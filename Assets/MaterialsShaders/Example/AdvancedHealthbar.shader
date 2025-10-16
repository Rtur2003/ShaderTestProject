/*
 * AdvancedHealthbar Shader
 *
 * Purpose: Feature-rich animated health bar with liquid effects
 * Use Case: Premium game UI, stylized health displays
 * Performance: Medium (noise calculations, animations)
 *
 * Features:
 * - Liquid wave animation with noise distortion
 * - Animated foam effect at liquid edge
 * - Rounded corner clipping (SDF-based)
 * - Customizable border
 * - Flash effect when low health
 * - Dynamic or static background modes
 * - Gradient texture support
 *
 * Learning: Advanced UI techniques, SDF, procedural noise
 */

Shader "URP/AdvancedHealthbar"
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
        Tags
        {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local _DYNAMICBACKGROUND_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float _Health;
                float _BorderSize;
                half4 _BorderColor;
                half4 _BarBackgroundStaticColor;
                float _FlashThreshold;
                float _FlashAmount;
                float _WaveFrequency;
                float _WaveAmplitude;
                float _WaveSpeed;
                float _NoiseScale;
                float _NoiseSpeed;
                half4 _FoamColor;
                float _FoamWidth;
                float _FoamPulse;
                float _FoamIntensityAmount;
            CBUFFER_END

            float InverseLerp(float a, float b, float v)
            {
                return (v-a)/(b-a);
            }

            float Hash(float2 p)
            {
                return frac(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
            }

            float Noise(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);
                f = f * f * (3.0 - 2.0 * f);

                float a = Hash(i);
                float b = Hash(i + float2(1.0, 0.0));
                float c = Hash(i + float2(0.0, 1.0));
                float d = Hash(i + float2(1.0, 1.0));

                return lerp(lerp(a, b, f.x), lerp(c, d, f.x), f.y);
            }

            Varyings vert (Attributes input)
            {
                Varyings output;
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = input.uv;
                return output;
            }

            half4 frag (Varyings input) : SV_Target
            {
                // Rounded corner clipping
                float2 coords = input.uv;
                coords.x *= 8;
                float2 pointOnLineSeg = float2(clamp(coords.x, 0.5, 7.5), 0.5);
                float sdf = distance(coords, pointOnLineSeg) * 2 - 1;
                clip(-sdf);

                // Border
                float borderSdf = sdf + _BorderSize;
                float pd = fwidth(borderSdf);
                float borderMask = 1 - saturate(borderSdf / pd);

                // Liquid effect
                float2 liquidUV = input.uv;
                if (input.uv.x < _Health)
                {
                    float wave = sin(input.uv.y * _WaveFrequency + _Time.y * _WaveSpeed) * _WaveAmplitude;
                    float noise = Noise(float2(input.uv.y * _NoiseScale, input.uv.y * _NoiseScale + _Time.y * _NoiseSpeed));
                    float noiseOffset = (noise - 0.5) * _WaveAmplitude * 0.5;
                    liquidUV.x += wave + noiseOffset;
                }

                float healthbarMask = _Health > liquidUV.x;

                // Foam Effect
                float foamMask = 0;
                float foamNoise = Noise(float2(input.uv.y * _NoiseScale, input.uv.y * _NoiseScale + _Time.y * _NoiseSpeed));
                if (abs(input.uv.x - _Health) < _FoamWidth * foamNoise && input.uv.x <= _Health)
                {
                    float foamIntensity = 1 - abs(input.uv.x - _Health) / _FoamWidth;
                    foamIntensity *= (sin(_Time.y * _FoamPulse) * 0.3 + 0.7);
                    foamMask = foamIntensity * _FoamIntensityAmount;
                }

                // Healthbar main texture
                half3 healthColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(_Health, input.uv.y)).rgb;

                half3 backgroundColor;
                #ifdef _DYNAMICBACKGROUND_ON
                    backgroundColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(_Health, input.uv.y * 0.75)).rgb;
                    backgroundColor = lerp(backgroundColor, half3(0, 0, 0), 0.925);
                    backgroundColor *= 0.8;
                #else
                    backgroundColor = _BarBackgroundStaticColor.rgb;
                #endif

                // Add Foam Color
                healthColor = lerp(healthColor, _FoamColor.rgb, foamMask * _FoamColor.a);

                // Flash Effect
                if (_Health <= _FlashThreshold)
                {
                    float flash = cos(_Time.y * 4) * _FlashAmount + 1;
                    healthColor *= flash;
                }

                // Combine colors
                half3 barColor = lerp(backgroundColor, healthColor, healthbarMask);
                half3 finalColor = lerp(_BorderColor.rgb, barColor, borderMask);

                float alpha = 1;
                alpha = max(alpha, foamMask * _FoamColor.a);

                return half4(finalColor, alpha);
            }
            ENDHLSL
        }
    }

    FallBack "Universal Render Pipeline/Unlit"
}
