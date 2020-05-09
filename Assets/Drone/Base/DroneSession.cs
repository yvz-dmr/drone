using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.UI;
using static DroneSession;

public class DroneSession : SingleInstance<DroneSession> {

    DroneRegistrationState _droneRegistrationState = DroneRegistrationState.RegistrationNotStarted;
    public DroneRegistrationState droneRegistrationState {
        get { return _droneRegistrationState; }
        private set {
            _droneRegistrationState = value;
            OnDroneRegistrationStateChangeEvent.Invoke(_droneRegistrationState);
        }
    }

    public enum DroneRegistrationState {
        RegistrationNotStarted,
        RegisterStarted,
        Registered,
        RegisterFailed,
    }

    public DroneRegistrationStateChangeEvent OnDroneRegistrationStateChangeEvent;
    public UnityEvent OnDroneRegisterStartedEvent;
    public UnityEvent OnRegisteredEvent;
    public DroneRegisterFailedEvent OnRegisterFailedEvent;
    public DroneConnectionEvent OnDroneConnectedEvent;
    public UnityEvent OnDroneDisconnectedEvent;

    public string RegisterError { get; private set; }
    public bool IsPlatformSupported { get; private set; }
    public bool IsRegistered { get; private set; }

    public bool IsDroneConnected => Drone != null;
    public Drone Drone { get; private set; }

    private DroneBridge droneBridge;
    void Awake() {
        InitalizeBridge();

        OnDroneRegisterStartedEvent.AddListener(OnDroneRegisterStarted);
        OnRegisteredEvent.AddListener(OnDroneRegistered);
        OnRegisterFailedEvent.AddListener(OnDroneRegisterFailed);
        OnDroneConnectedEvent.AddListener(OnDroneConnected);
        OnDroneDisconnectedEvent.AddListener(OnDroneDisconnected);

    }

    private void Start() {
        droneBridge?.Initialize();
        Register();
    }

    private void Register() {
        OnDroneRegisterStartedEvent.Invoke();
        if (!IsPlatformSupported) {
            OnRegisterFailedEvent.Invoke($"{Application.platform} için drone desteği bulunmuyor");
            return;
        }
        droneBridge?.Register();
    }

    /// <summary>
    /// Registers drone again if previous registration failed
    /// </summary>
    public void ReRegister() {
        if (IsRegistered)
            return;
        Register();
    }

    private void OnDroneRegisterStarted() {
        droneRegistrationState = DroneRegistrationState.RegisterStarted;
        Debug.Log("Drone registration started");
    }
    private void OnDroneRegisterFailed(string error) {
        RegisterError = error;
        IsRegistered = false;
        droneRegistrationState = DroneRegistrationState.RegisterFailed;
        Debug.Log($"Registration failed {error}");
    }

    private void OnDroneRegistered() {
        IsRegistered = true;
        RegisterError = "";
        droneRegistrationState = DroneRegistrationState.Registered;
        Debug.Log("Drone registered");
    }

    void OnDroneConnected(Drone drone) {
        Debug.Log($"Drone {drone.Name} connected");
    }

    void OnDroneDisconnected() {
        Debug.Log("Drone disconnected");
    }

    Queue<Action> eventQueue = new Queue<Action>();
    void InitalizeBridge() {
        droneBridge = DroneBridge.Create();
        if(droneBridge == null) {
            Debug.Log("No drone bridge found for " + Application.platform);
            IsPlatformSupported = false;
            return;
        }

        IsPlatformSupported = true;
        droneBridge.OnRegistered += () => eventQueue.Enqueue(() => OnRegisteredEvent.Invoke());
        droneBridge.OnRegisterFailed += (error) => eventQueue.Enqueue(() => OnRegisterFailedEvent.Invoke(error));
        droneBridge.OnDroneConnected += (drone) => {
            Drone = drone;
            eventQueue.Enqueue(() => OnDroneConnectedEvent.Invoke(drone));
        };
        droneBridge.OnDroneDisconnected += () => {
            Drone = null;
            eventQueue.Enqueue(() => OnDroneDisconnectedEvent.Invoke());
        };
    }

    private void Update() {
        if(Drone != null) {
            Drone.Update();
        }
    }

    private void LateUpdate() {
        while(eventQueue.Count > 0) {
            eventQueue.Dequeue()?.Invoke();
        }
    }

}

[Serializable]
public class DroneRegistrationStateChangeEvent : UnityEvent<DroneRegistrationState> {

}

[Serializable]
public class DroneRegisterFailedEvent : UnityEvent<string> {

}

[Serializable]
public class DroneConnectionEvent : UnityEvent<Drone> {

}