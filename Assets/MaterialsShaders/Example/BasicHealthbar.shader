/*
 * BasicHealthbar Shader
 *
 * Purpose: Simple UI health bar with color gradient
 * Use Case: Game UI, health/mana/energy bars
 * Performance: Very Low (UI shader)
 *
 * Features:
 * - Health-based fill mask
 * - Color gradient (red → green)
 * - Smooth color transition
 * - Transparency support
 *
 * Learning: UI shader basics, masking techniques
 */

Shader "URP/BasicHealthbar"
{
    Properties
    {
       [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
        _Health ("Health", Range(0,1)) = 1.0
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
            CBUFFER_END

            // Inverse lerp: converts value from [a,b] range to [0,1]
            float InverseLerp(float a, float b, float v)
            {
                return (v - a) / (b - a);
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
                // Health bar mask
                float healthbarMask = _Health > input.uv.x;

                // Color transition from red to green based on health
                float tHealth = saturate(InverseLerp(0.3, 0.8, _Health));
                half3 healthColor = lerp(half3(1, 0, 0), half3(0, 1, 0), tHealth);

                // Apply mask
                half3 finalColor = healthColor * healthbarMask;

                return half4(finalColor, 1.0);
            }
            ENDHLSL
        }
    }

    FallBack "Universal Render Pipeline/Unlit"
}
