using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public abstract class DroneBridge
{
    public Action OnRegistered;
    public Action<string> OnRegisterFailed;
    public Action<Drone> OnDroneConnected;
    public Action OnDroneDisconnected;

    public Drone Drone { get; protected set; }

    public bool IsInitialized { get; private set; }
    public void Initialize() {
       if(!IsInitialized) {
            IsInitialized = true;
            DoInitialize();
        }
    }

    public abstract void Register();

    protected abstract void DoInitialize();

    public static DroneBridge Create() {
        return
#if UNITY_EDITOR
            null;
#elif UNITY_ANDROID
            new AndroidDroneBridge()
#elif UNITY_IOS
            new IOSDroneBridge()
#else
            null
#endif
        ;
    }

}
