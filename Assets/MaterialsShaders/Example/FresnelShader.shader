/*
 * Fresnel Shader
 *
 * Purpose: Demonstrates Fresnel effect (angle-based lighting)
 * Use Case: Force fields, energy shields, soap bubbles, rim lighting
 * Performance: Very Low (simple dot product calculation)
 *
 * Features:
 * - Pure Fresnel effect visualization
 * - Adjustable power and intensity
 * - Color customization
 * - Transparency support
 * - Inverted Fresnel option
 *
 * Learning: Fresnel equations, view-dependent effects
 */

Shader "URP/FresnelShader"
{
    Properties
    {
        [Header(Fresnel Settings)]
        _FresnelColor ("Fresnel Color", Color) = (0, 1, 1, 1)
        _FresnelPower ("Fresnel Power", Range(0, 10)) = 3
        _FresnelIntensity ("Fresnel Intensity", Range(0, 5)) = 1
        [Toggle] _InvertFresnel ("Invert Fresnel", Float) = 0

        [Header(Base Settings)]
        _BaseColor ("Base Color", Color) = (0, 0, 0, 0)
        _Alpha ("Alpha", Range(0, 1)) = 0.5
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

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local _INVERTFRESNEL_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                float3 viewDirWS : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _FresnelColor;
                float _FresnelPower;
                float _FresnelIntensity;
                half4 _BaseColor;
                float _Alpha;
            CBUFFER_END

            Varyings vert (Attributes input)
            {
                Varyings output;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);

                output.positionHCS = positionInputs.positionCS;
                output.normalWS = normalInputs.normalWS;
                output.viewDirWS = GetWorldSpaceNormalizeViewDir(positionInputs.positionWS);

                return output;
            }

            half4 frag (Varyings input) : SV_Target
            {
                // Normalize vectors
                float3 normalWS = normalize(input.normalWS);
                float3 viewDirWS = normalize(input.viewDirWS);

                // Calculate Fresnel
                float NdotV = saturate(dot(normalWS, viewDirWS));

                #ifdef _INVERTFRESNEL_ON
                    float fresnel = pow(NdotV, _FresnelPower);
                #else
                    float fresnel = pow(1.0 - NdotV, _FresnelPower);
                #endif

                fresnel *= _FresnelIntensity;

                // Combine base color and fresnel
                half3 finalColor = _BaseColor.rgb + _FresnelColor.rgb * fresnel;

                // Alpha
                float alpha = _Alpha + fresnel * _FresnelColor.a;
                alpha = saturate(alpha);

                return half4(finalColor, alpha);
            }
            ENDHLSL
        }
    }

    FallBack "Universal Render Pipeline/Unlit"
}
