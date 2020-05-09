/*using Mapbox.Unity.Location;
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DroneLocationProvider : MonoBehaviour, ILocationProvider
{
    bool hasReceivedAnyLocation;
    public bool HasReceivedAnyLocation => hasReceivedAnyLocation;

    Location currentLocation = new Location();
    public Location CurrentLocation => currentLocation;

    public event Action<Location> OnLocationUpdated;

    [SerializeField] float updateInterval = 0.25f;

    private float nextUpdate;
    private Drone drone;

    void Awake() {
        drone = DroneSession.Instance.Drone;

        if (DroneSession.Instance.IsDroneConnected) {
            LocationManager.Instance.SetLocationProvider(this);
        }

        DroneSession.Instance.OnDroneConnectedEvent.AddListener(OnDroneConnected);
        DroneSession.Instance.OnDroneDisconnectedEvent.AddListener(OnDroneDisconnected);
    }

    private void OnDestroy() {
        if(DroneSession.Instance!= null) {
            DroneSession.Instance.OnDroneConnectedEvent.RemoveListener(OnDroneConnected);
            DroneSession.Instance.OnDroneDisconnectedEvent.RemoveListener(OnDroneDisconnected);
        }
        
    }

    void Update() {
        if(drone != null && Time.unscaledTime >= nextUpdate) {
            nextUpdate = updateInterval + Time.unscaledTime;
            GetLocation();
        }
    }

    private void GetLocation() {
        var droneLocation = drone.GetGPSState();

        //Debug.Log($"GPS State: {droneLocation.ToString()}");

        if (droneLocation.signalLevel <= 0)
            return;

        hasReceivedAnyLocation = true;

        currentLocation.Altitude = droneLocation.altitude;
        currentLocation.LatitudeLongitude = new Mapbox.Utils.Vector2d(droneLocation.latitude, droneLocation.longitude);
        currentLocation.UserHeading = drone.GetDroneHeading();

        currentLocation.SatellitesInView = droneLocation.satelliteCount;
        currentLocation.IsLocationUpdated = true;
        currentLocation.IsUserHeadingUpdated = true;

        OnLocationUpdated?.Invoke(currentLocation);
    }

    private void OnDroneConnected(Drone drone) {
        this.drone = drone;
        LocationManager.Instance.SetLocationProvider(this);
    }

    void OnDroneDisconnected() {
        drone = null;
        LocationManager.Instance.RemoveLocationProvider(this);
    }

}
*/