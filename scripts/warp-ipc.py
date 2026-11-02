#!/usr/bin/env python3
"""
Bypass warp-cli's 5-second IPC timeout by talking directly to warp-svc daemon.
"""
import json
import socket
import uuid
import sys
import time

SOCKET_PATH = "/run/cloudflare-warp/warp_service"
IPC_RECV_TIMEOUT = 20  # seconds

def msg_send(sock, msg_type: int, body: str | bytes):
    """Send IPC message: 8-byte header + body."""
    if isinstance(body, str):
        body = body.encode()
    header = bytes([msg_type]) + b'\x00' * 7
    payload = header + body
    sock.sendall(payload)
    print(f"  [SENT] type={msg_type:#04x} ({len(body)} bytes): {body[:120]}...")

def msg_recv(sock, timeout=IPC_RECV_TIMEOUT):
    """Receive one IPC message with timeout."""
    sock.settimeout(timeout)
    try:
        header = sock.recv(8)
        if not header or len(header) < 8:
            return None, None
        msg_type = header[0]
        # Read body - read until no more data or timeout
        body_parts = []
        while True:
            sock.settimeout(0.1)  # short timeout between chunks
            try:
                chunk = sock.recv(65536)
                if not chunk:
                    break
                body_parts.append(chunk)
            except socket.timeout:
                break
            except BlockingIOError:
                break
        body = b''.join(body_parts)
        sock.settimeout(None)  # reset
        return msg_type, body
    except socket.timeout:
        return None, None
    except Exception as e:
        print(f"  [ERROR] recv: {e}")
        return None, None

def msg_type_for_request(request_name: str) -> int:
    """Determine message type for a given request name."""
    # Observed mappings from strace:
    type_map = {
        "get_app_settings": 0x4A,   # 'J'
        "new_registration": 0x4A,   # 'J'
        "get_registration_info": 0x4F,  # 'O'
        "delete_registration": 0x4D,    # 'M'
    }
    return type_map.get(request_name, 0x4A)  # default 'J'

def do_request(sock, request_name: str) -> tuple[int, bytes | None]:
    """Send a request and get response."""
    req_id = str(uuid.uuid4())
    body = json.dumps({"id": req_id, "request": request_name}).encode()
    msg_type = msg_type_for_request(request_name)
    msg_send(sock, msg_type, body)
    
    # Read response - may include intermediate broadcast messages
    while True:
        mtype, body = msg_recv(sock)
        if mtype is None:
            print(f"  [TIMEOUT] No response for '{request_name}'")
            return None, None
        if body is None:
            return mtype, None
        try:
            data = json.loads(body)
            if data.get("id") == req_id:
                return mtype, data
            # Not our response - print as event and continue
            resp = data.get("response", {})
            if "transient_update" in resp:
                print(f"  [EVENT] transient_update: {resp['transient_update']}")
            elif "ipc_status" in resp:
                print(f"  [STATUS] ipc_status: {resp['ipc_status']}")
            elif "registration_info" in resp or "app_settings" in resp:
                return mtype, data
            else:
                print(f"  [OTHER] {list(resp.keys())[:3]}")
        except json.JSONDecodeError:
            print(f"  [PARSE ERROR] {body[:200]}")
            return mtype, body

def main():
    print("=== WARP IPC Direct ===")
    
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        sock.connect(SOCKET_PATH)
        print(f"[CONNECTED] to {SOCKET_PATH}")
    except Exception as e:
        print(f"[FAILED] connect: {e}")
        sys.exit(1)
    
    # Step 1: Read initial broadcast messages
    print("\n[STEP 1] Reading initial broadcasts...")
    for _ in range(5):
        mtype, body = msg_recv(sock)
        if mtype is None:
            break
        if body:
            try:
                data = json.loads(body)
                resp = data.get("response", {})
                if "transient_update" in resp:
                    print(f"  [EVENT] transient_update: {resp['transient_update']}")
                elif "app_settings" in resp:
                    print(f"  [INIT] got app_settings")
                else:
                    print(f"  [MSG] type={mtype:#04x} keys={list(resp.keys())[:3]}")
            except:
                print(f"  [MSG] type={mtype:#04x} raw={body[:80]}")
    
    # Step 2: Delete registration
    print("\n[STEP 2] Deleting registration...")
    mtype, data = do_request(sock, "delete_registration")
    if data:
        resp = data.get("response", {})
        if "ipc_status" in resp:
            print(f"  [DELETE] status: {resp['ipc_status']}")
        else:
            print(f"  [DELETE] response: {data}")
    else:
        print("  [DELETE] no response")
    
    # Step 3: New registration
    print(f"\n[STEP 3] New registration (timeout={IPC_RECV_TIMEOUT}s)...")
    mtype, data = do_request(sock, "new_registration")
    if data:
        resp = data.get("response", {})
        if "ipc_status" in resp:
            print(f"  [REGISTER] status: {resp['ipc_status']}")
        elif "registration_info" in resp:
            info = resp["registration_info"]
            print(f"  [REGISTER] SUCCESS! Account type: {info.get('account_type')}")
            print(f"  [REGISTER] ID: {info.get('id')}")
            print(f"  [REGISTER] Warp Enabled: {info.get('warp_enabled')}")
        else:
            print(f"  [REGISTER] response: {data}")
    else:
        print("  [REGISTER] FAILED - no response within timeout")
    
    sock.close()
    print("\n[DONE]")

if __name__ == "__main__":
    main()
