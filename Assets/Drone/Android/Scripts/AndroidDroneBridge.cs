using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AndroidDroneBridge : DroneBridge
{
    public const string PLUGIN_BUNDLE_ID = "com.turkcell.droneplugin";

    class DroneConnectionCallback : AndroidJavaProxy {
        DroneBridge bridge;
        public DroneConnectionCallback(DroneBridge bridge) : base($"{PLUGIN_BUNDLE_ID}.DroneBridge$DroneConnectionCallback") {
            this.bridge = bridge;
        }
        void OnRegistered() {
            bridge.OnRegistered?.Invoke();
        }
        void OnRegisterFailed(string error) {
            bridge.OnRegisterFailed?.Invoke(error);
        }
        void OnDroneConnected(AndroidJavaObject drone) {
            bridge.OnDroneConnected?.Invoke(new AndroidDrone(drone));
        }
        void OnDroneDisconnected() {
            bridge.OnDroneDisconnected?.Invoke();
        }
    }

    AndroidJavaObject nativeDroneBridge;
    protected override void DoInitialize() {
        AndroidJavaClass unityPlayerClass = new AndroidJavaClass("com.unity3d.player.UnityPlayer");
        AndroidJavaObject activity = unityPlayerClass.GetStatic<AndroidJavaObject>("currentActivity");
        nativeDroneBridge = new AndroidJavaObject($"{PLUGIN_BUNDLE_ID}.DroneBridge");
        nativeDroneBridge.Call("Initialize", new object[] { activity, new DroneConnectionCallback(this) });
    }

    public override void Register() {
        if (!IsInitialized) {
            OnRegisterFailed("Drone bridge needs to be initialized before register");
            return;
        }

        nativeDroneBridge.Call("StartSDKRegistration");
    }
}
