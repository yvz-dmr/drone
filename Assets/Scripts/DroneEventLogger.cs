using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DroneEventLogger : MonoBehaviour
{
    public DroneSession session;

    private void Awake() {

        session.OnDroneConnectedEvent.AddListener((drone) => Logger.Instance.Log("{drone.Name} Connected"));
        session.OnDroneDisconnectedEvent.AddListener(() => Logger.Instance.Log("Drone disconnected"));
        session.OnDroneRegistrationStateChangeEvent.AddListener((state) => Logger.Instance.Log("State " + state));
        session.OnRegisteredEvent.AddListener(() => Logger.Instance.Log("Registered"));
        session.OnRegisterFailedEvent.AddListener((str) => Logger.Instance.Log("Register failed " + str));

    }

    
}
