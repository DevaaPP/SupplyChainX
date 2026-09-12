import uvicorn
import sys
import os
import socket

# Add backend directory to sys.path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

def get_local_ips():
    valid = []
    try:
        hostname = socket.gethostname()
        for ip in socket.gethostbyname_ex(hostname)[2]:
            if not ip.startswith("127.") and not ip.startswith("169.254."):
                valid.append(ip)
    except Exception:
        pass
    return valid

if __name__ == "__main__":
    ips = get_local_ips()
    primary_ip = ips[0] if ips else "127.0.0.1"

    print("=================================================================")
    print(" SupplyChainX Backend Server Starting (Multi-Device Ready)...")
    print(f" Localhost:              http://127.0.0.1:8000/docs")
    print(f" Multi-Device LAN/PAN:   http://{primary_ip}:8000/docs")
    print(f" API Base URL:           http://{primary_ip}:8000/api/v1")
    if len(ips) > 1:
        print(f" Other Detected IPs:     {', '.join(ips[1:])}")
    print("-----------------------------------------------------------------")
    print(" To launch Flutter Web for 5 devices on this same network:")
    print(f" flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000")
    print(f" Then all 5 devices open: http://{primary_ip}:3000")
    print("=================================================================")
    try:
        uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=False)
    except Exception as exc:
        print("[CRITICAL] Server failed to start:", exc)
