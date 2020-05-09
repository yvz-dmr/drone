using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.UI;

public class DroneFunctionTester : MonoBehaviour
{
    public Button buttonPrefab;
    public Transform buttonContainer;

    Drone drone;

    private void Start() {
        CreateButton("Name", () => drone.Name);
        CreateButton("Heading", () => drone.GetDroneHeading().ToString());
        CreateButton("Drone Rotation", () => drone.GetDroneRotation().eulerAngles.ToString());
        CreateButton("Camera Rotation", () => drone.GetDroneCameraRotation().eulerAngles.ToString());
        CreateButton("Gps State", () => drone.GetGPSState().ToString());
    }

    

    void CreateButton(string actionName, Func<string> action) {
        var button = Instantiate(buttonPrefab, buttonContainer);
        button.GetComponentInChildren<Text>().text = actionName;
        button.onClick.AddListener(() => Logger.Instance.Log(actionName + ": " + action?.Invoke()));
    }


    public void OnDroneConnected(Drone drone) {
        gameObject.SetActive(true);
        this.drone = drone;
    }

    public void OnDroneDisconnected() {
        gameObject.SetActive(false);
    }
}
