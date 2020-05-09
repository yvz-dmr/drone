#if (UNITY_IPHONE && !UNITY_EDITOR)
#define IS_IOS_PLATFORM
#endif
using System;
using UnityEngine;

#if IS_IOS_PLATFORM
using System.Runtime.InteropServices;
#endif

public class IOSDroneBridgeEventListener : MonoBehaviour
{

    static IOSDroneBridgeEventListener instance;
    public static IOSDroneBridgeEventListener Instance
    {
        get
        {
            if (instance == null)
            {
                var go = new GameObject(nameof(IOSDroneBridgeEventListener));
                instance = go.AddComponent<IOSDroneBridgeEventListener>();
            }
            return instance;
        }
    }

    public IOSDroneBridge bridge;

    public void OnRegistered()
    {
        bridge.OnRegistered?.Invoke();
    }

    public void OnRegisterFailed(string err)
    {
        bridge.OnRegisterFailed?.Invoke(err);
    }

    public void OnDroneConnected()
    {
        bridge.OnDroneConnected?.Invoke(new IOSDrone());
    }

    public void OnDroneDisconnected()
    {
        bridge.OnDroneDisconnected?.Invoke();
    }
}

public class IOSDroneBridge : DroneBridge
{
    const string className = "IOSDroneBridge";

#if UNITY_EDITOR
    const string debugData = "{\"signalLevel\":\"1.4\",\"latitude\":\"12.2222\",\"longitude\":\"14.4444\",\"altitudeFromGround\":\"23.999\",\"satelliteCount\":\"28\",\"isFlying\":\"1\",\"GetDroneAttitude\":[\"0\",\"1\",\"2\"],\"GetModelName\":\"Remote\",\"takeoffLocationAltitude\":\"43.3333\"}";
#endif

#if IS_IOS_PLATFORM
    [DllImport("__Internal")]
    private static extern void _DJI_Register();

    [DllImport("__Internal")]
    private static extern void _DJI_SetDebugDroneActivate(bool state, string ipAddress);
#endif

    public override void Register()
    {
#if IS_IOS_PLATFORM
          _DJI_Register();
#endif
    }

    /// <summary>
    /// Initilize gameobject first so that all
    /// the native methods will be accessible
    /// </summary>
    protected override void DoInitialize()
    {
        IOSDroneBridgeEventListener.Instance.bridge = this;
    }
}
