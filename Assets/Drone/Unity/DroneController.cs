using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DroneController : MonoBehaviour
{
    [SerializeField] Transform cameraGimbalTransform;

    public Transform CameraGimbalTransform => cameraGimbalTransform;

    private Drone drone;

    private void Awake() {
        drone = DroneSession.Instance.Drone;

        if (DroneSession.Instance.IsDroneConnected)
            HandleDroneConnection(DroneSession.Instance.Drone);

        DroneSession.Instance.OnDroneConnectedEvent.AddListener(HandleDroneConnection);
        DroneSession.Instance.OnDroneDisconnectedEvent.AddListener(HandleDroneDisconnection);
    }

    private void OnDestroy() {
        if(DroneSession.Instance != null) {
            DroneSession.Instance.OnDroneConnectedEvent.RemoveListener(HandleDroneConnection);
            DroneSession.Instance.OnDroneDisconnectedEvent.RemoveListener(HandleDroneDisconnection);
        }
    }

    private void HandleDroneDisconnection() {
        drone = null;
    }

    void HandleDroneConnection(Drone drone) {
        this.drone = drone;
    }

    private void Update() {
        if(drone != null) {
            var rotation = drone.GetDroneCameraRotation(); 
            cameraGimbalTransform.localRotation = rotation;

        }
    }
}
