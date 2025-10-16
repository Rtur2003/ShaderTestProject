Shader "Unlit/AdvancedHealthbar"
{
    Properties
    {
        [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
        _Health ("Health", Range(0,1)) = 1.0
        _BorderSize("Border Size",Range(0,0.5))= 0.3
        _BorderColor("Border Color",Color)=(1,1,1,1)
        [Toggle] _DynamicBackground("Dynamic Background",Float)= 1
        _BarBackgroundStaticColor("Bar Background Static Color",Color)=(0,0,0,1)
        _FlashThreshold("Flash Threshold",Range(0,1))=0.2
        _FlashAmount("Flash Amount",Range(0.1,0.9))=0.5
        
        _WaveFrequency("Wave Frequency", Range(0, 20)) = 0.25
        _WaveAmplitude("Wave Amplitude", Range(0, 0.1)) = 0.02
        _WaveSpeed("Wave Speed", Range(0, 5)) = 0.0
        _NoiseScale("Noise Scale", Range(0, 10)) = 4.0
        _NoiseSpeed("Noise Speed", Range(0, 2)) = 2.0
        _FoamColor("Foam Color", Color) = (1.0, 1.0, 1.0, 0.32)
        _FoamWidth("Foam Width", Range(0, 0.1)) = 0.0373
        _FoamPulse("Foam Pulse",Range(0,10))= 2.0
        _FoamIntensityAmount("Foam Intensity Amount",Range(0,5))= 5.0
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
            #pragma shader_feature _DYNAMICBACKGROUND_ON

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
            float _BorderSize;
            float4 _BorderColor;
            float4 _BarBackgroundStaticColor;
            float _FlashThreshold;
            float _FlashAmount;

            float _WaveFrequency;
            float _WaveAmplitude;
            float _WaveSpeed;
            float _NoiseScale;
            float _NoiseSpeed;
            float4 _FoamColor;
            float _FoamWidth;
            float _FoamPulse;
            float _FoamIntensityAmount;

            Interpolators vert (MeshData v)
            {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            // Set thresholds to certain points. For example if a<0.2 then returns red every health value...
            float InverseLerp(float a, float b, float v)
            {
                return (v-a)/(b-a);
            }

            float Hash(float2 p)
            {
                // Special hash calculation ("IQ Hash" - Inigo Quilez)
                return frac(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
            }

            float Noise(float2 p)
            {
                float2 i = floor(p);    // Grid cell coordinates
                float2 f = frac(p);     // Coordinates inside cell (between 0 and 1)
                f = f * f * (3.0 - 2.0 * f);    //Cubic Hermine Curve, Same as SmoothStep()
                // f= smoothstep(0.,1.,f);       // Same

                // Four corners in 2D of a tile
                float a = Hash(i);
                float b = Hash(i + float2(1.0, 0.0));
                float c = Hash(i + float2(0.0, 1.0));
                float d = Hash(i + float2(1.0, 1.0));
    
                return lerp(lerp(a, b, f.x), lerp(c, d, f.x), f.y);
            }


            float4 frag (Interpolators i) : SV_Target
            {
                //Rounded corner clipping
                float2 coords=i.uv;
                coords.x*=8;
                float2 pointOnLineSeg=float2(clamp(coords.x,0.5,7.5),0.5);
                float sdf=distance(coords,pointOnLineSeg)*2-1;
                clip(-sdf);

                //Border
                float borderSdf=sdf+_BorderSize;
                float pd=fwidth(borderSdf);             // Screen space partial derivative
                float borderMask=1-saturate(borderSdf/pd); // For Anti-Aliasing
                //float borderMask=step(0,-borderSdf);     // Without Anti-Aliasing


                // Liquid effect 
                float2 liquidUV = i.uv;
                if (i.uv.x < _Health)
                {
                    // Sin wave
                    float wave = sin(i.uv.y * _WaveFrequency + _Time.y * _WaveSpeed) * _WaveAmplitude;
                    
                    // Noise distortion
                    float noise = Noise(float2(i.uv.y * _NoiseScale, i.uv.y * _NoiseScale + _Time.y * _NoiseSpeed));
                    float noiseOffset = (noise - 0.5) * _WaveAmplitude * 0.5;
                    
                    liquidUV.x += wave + noiseOffset;
                }

                
                float healthbarMask=_Health > liquidUV.x;          //if you want to life is increase or decrease part by part use floor(i.uv.x*partCount)/partCount;
                                                                // Mathf.Lerp() --> clamped ... lerp() --> unclamped
                
                // Foam Effect
                float foamMask = 0;
                float foamNoise= Noise(float2(i.uv.y * _NoiseScale, i.uv.y * _NoiseScale + _Time.y * _NoiseSpeed));
                if (abs(i.uv.x - _Health) < _FoamWidth*foamNoise && i.uv.x <= _Health)
                {
                    float foamIntensity = 1 - abs(i.uv.x - _Health) / _FoamWidth;
                    // Foam Pulse Effect
                    foamIntensity *= (sin(_Time.y * _FoamPulse) * 0.3 + 0.7);
                    foamMask = foamIntensity*_FoamIntensityAmount;
                }

                //Healthbar main texture
                float3 healthColor=tex2D(_MainTex,float2(_Health, i.uv.y));


                float3 backgroundColor;

                // If else state to change between dynamic and static states of healthbar background mode
                #ifdef _DYNAMICBACKGROUND_ON
                backgroundColor=tex2D(_MainTex,float2(_Health,i.uv.y*.75));
                backgroundColor = lerp(backgroundColor, float3(0,0,0), 0.925);
                backgroundColor *= 0.8;
                #else
                backgroundColor=_BarBackgroundStaticColor;
                #endif
                
                
                // Add Foam Color Values
                healthColor = lerp(healthColor, _FoamColor.rgb, foamMask * _FoamColor.a);
                
                //Flash Effect
                if (_Health<=_FlashThreshold)
                {
                    float flash=cos(_Time.y*4)*_FlashAmount+1;
                    healthColor*=flash;
                }

                // HealthBar Background color
                float3 barColor=lerp(backgroundColor, healthColor,healthbarMask); 

                // Combine border and health
                float3 finalColor = lerp(_BorderColor.rgb, barColor, borderMask);
                float alpha=1;
                alpha = max(alpha, foamMask * _FoamColor.a);
                
                return float4(finalColor,alpha);
                //return float4(healthColor*healthbarMask*borderMask,1); // Without border color (black border)
            }
            ENDCG
        }
    }
}
