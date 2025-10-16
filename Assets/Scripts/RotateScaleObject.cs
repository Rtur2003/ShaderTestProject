using System;
using UnityEngine;
using Random = System.Random;

public class RotateScaleObject : MonoBehaviour
{
   [Header("Rotation Settings (You can't change rotation settings during playtime!!)")]
   [SerializeField] private float rotateSpeed=30f;
   [SerializeField] private bool isRotating = false;
   [SerializeField] private bool rotateOnY = true;
   [SerializeField] private bool rotateOnX = false;   
   [SerializeField] private bool rotateOnZ = false;
   [SerializeField] private bool randomizeSpeed = false;
   [SerializeField] private float minSpeed = 20f;
   [SerializeField] private float maxSpeed = 60f;
   
   [Header("Grow Settings")]
   [SerializeField] private bool isGrowing = false;
   [SerializeField] private float growSpeed = .25f;
   [SerializeField] private float maxSize= 1.25f;
   [SerializeField] private float minSize= .25f;
   
   private Vector3 rotationAxis;
   private bool currentlyGrowing = true;
   private Vector3 initialScale;


   private void Start()
   {
      if (randomizeSpeed)
      {
         rotateSpeed=UnityEngine.Random.Range(minSpeed, maxSpeed);
      }
      
      rotationAxis = Vector3.zero;
      
      if (isRotating)
      {
         if (rotateOnY) rotationAxis.y = 1;
         if (rotateOnX) rotationAxis.x = 1;
         if (rotateOnZ) rotationAxis.z = 1;
         
         if(rotationAxis == Vector3.zero) 
         {
            rotationAxis.x =0;
            rotationAxis.y=0; 
            rotationAxis.z=0;
         }
      }
      initialScale = transform.localScale;
      currentlyGrowing = isGrowing;
   }

   private void Update()
   {
      if (isRotating && rotationAxis != Vector3.zero)
      {
         transform.Rotate(rotationAxis * rotateSpeed * Time.deltaTime);
      }
      if (isGrowing)
      {
         Resize();   
      }
   }

   private void Resize()
   {
      float currentScale = transform.localScale.x;
      if (currentlyGrowing)
      {
         transform.localScale += Vector3.one * growSpeed * Time.deltaTime;
         if (transform.localScale.x >= maxSize)
         {
            currentlyGrowing = false;
            transform.localScale = Vector3.one * maxSize;
         }
      }
      else
      {
         transform.localScale -= Vector3.one * growSpeed * Time.deltaTime;
         if (transform.localScale.x <= minSize)
         {
            currentlyGrowing = true;
            transform.localScale = Vector3.one * minSize;
         }
      }
   }
}
