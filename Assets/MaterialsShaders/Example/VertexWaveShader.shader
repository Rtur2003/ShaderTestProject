/*
 * VertexWaveShader
 *
 * Purpose: Vertex displacement with sine wave animation
 * Use Case: Water surfaces, cloth simulation, flags, organic movement
 * Performance: Low (vertex shader math)
 *
 * Features:
 * - Procedural wave displacement
 * - Adjustable frequency, amplitude, speed
 * - Vertex-based animation (GPU efficient)
 * - No texture required
 *
 * Learning: Vertex shader manipulation basics
 */

Shader "URP/VertexWaveShader"
{
    Properties
    {
        _Color ("Color", Color) = (0.2, 0.5, 1.0, 1.0)
        _Speed ("Wave Speed", Range(0, 5)) = 1
        _Height ("Wave Height", Range(0, 1)) = 0.25
        _Frequency ("Wave Frequency", Range(0, 10)) = 3
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
        }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _Color;
                float _Speed;
                float _Height;
                float _Frequency;
            CBUFFER_END

            Varyings vert (Attributes input)
            {
                Varyings output;

                // Apply wave displacement
                float wave = sin(input.positionOS.x * _Frequency + _Time.y * _Speed) * _Height;
                input.positionOS.y += wave;

                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);

                return output;
            }

            half4 frag (Varyings input) : SV_Target
            {
                return _Color;
            }
            ENDHLSL
        }
    }

    FallBack "Universal Render Pipeline/Unlit"
}
