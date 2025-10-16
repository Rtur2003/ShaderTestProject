Shader "Unlit/BasicHealthbar"
{
    Properties
    {
       [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
        _Health ("Health", Range(0,1)) = 1.0 
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}

        Pass
        {
            ZWrite Off
            
            // src * SrcAlpha dst * (1-srcAlpha)
            Blend SrcAlpha OneMinusSrcAlpha //Alpha Blending
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct MeshData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float _Health;

            Interpolators vert (MeshData v)
            {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            // Set thresholds to certain points. For example if a<0.2 then returns red every point...
            float InverseLerp(float a, float b, float v)
            {
                return (v-a)/(b-a);
            }

            float4 frag (Interpolators i) : SV_Target
            {
                float healthbarMask=_Health > i.uv.x;          //if you want to life is increase or decrease part by part use floor(i.uv.x*partCount)/partCount;
                                                                // Mathf.Lerp() --> clamped ... lerp() --> unclamped
                 //clip(healthbarMask-.5);
                
                float tHealth=saturate(InverseLerp(0.3,0.8,_Health));  // saturate function is clamping the values between 0 and 1
                float3 healthColor=lerp(float3(1,0,0),float3(0,1,0),tHealth);

                //float3 backgroundColor=float3(0,0,0);
                //float3 outputColor=lerp(backgroundColor,healthColor,healthbarMask);
                
                return float4(healthColor*healthbarMask,1);
            }
            ENDCG
        }
    }
}
