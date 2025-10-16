/*
 * Toon/Cel Shader
 *
 * Purpose: Stylized cartoon/anime lighting effect
 * Use Case: Stylized games, anime-style rendering, non-photorealistic visuals
 * Performance: Low (stepped lighting calculations)
 *
 * Features:
 * - Multi-step diffuse shading (cel shading)
 * - Rim lighting for outlines
 * - Adjustable shadow steps
 * - Specular highlights with toon style
 * - Customizable color palette
 *
 * Learning: Non-photorealistic rendering (NPR) techniques
 */

Shader "URP/ToonShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1, 1, 1, 1)

        [Header(Toon Shading)]
        _ShadowSteps ("Shadow Steps", Range(1, 10)) = 3
        _ShadowColor ("Shadow Color", Color) = (0.3, 0.3, 0.4, 1)
        _ShadowSmoothness ("Shadow Smoothness", Range(0, 0.5)) = 0.05

        [Header(Rim Light)]
        _RimColor ("Rim Color", Color) = (1, 1, 1, 1)
        _RimPower ("Rim Power", Range(0, 10)) = 3
        _RimIntensity ("Rim Intensity", Range(0, 2)) = 1

        [Header(Specular)]
        _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
        _SpecularSize ("Specular Size", Range(0, 1)) = 0.1
        _SpecularSmoothness ("Specular Smoothness", Range(0, 0.5)) = 0.05
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
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD2;
                float3 positionWS : TEXCOORD3;
                float fogCoord : TEXCOORD4;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                half4 _Color;
                float _ShadowSteps;
                half4 _ShadowColor;
                float _ShadowSmoothness;
                half4 _RimColor;
                float _RimPower;
                float _RimIntensity;
                half4 _SpecularColor;
                float _SpecularSize;
                float _SpecularSmoothness;
            CBUFFER_END

            Varyings vert (Attributes input)
            {
                Varyings output;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);

                output.positionHCS = positionInputs.positionCS;
                output.positionWS = positionInputs.positionWS;
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                output.normalWS = normalInputs.normalWS;
                output.viewDirWS = GetWorldSpaceNormalizeViewDir(positionInputs.positionWS);
                output.fogCoord = ComputeFogFactor(positionInputs.positionCS.z);

                return output;
            }

            half4 frag (Varyings input) : SV_Target
            {
                // Sample texture
                half4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                half4 baseColor = texColor * _Color;

                // Normalize vectors
                float3 normalWS = normalize(input.normalWS);
                float3 viewDirWS = normalize(input.viewDirWS);

                // Get main light
                Light mainLight = GetMainLight();
                float3 lightDir = normalize(mainLight.direction);
                half3 lightColor = mainLight.color;

                // Diffuse lighting (N dot L)
                float NdotL = dot(normalWS, lightDir);

                // Toon shading with steps
                float lightIntensity = smoothstep(0, _ShadowSmoothness, NdotL);
                lightIntensity = floor(lightIntensity * _ShadowSteps) / _ShadowSteps;

                // Shadow color blending
                half3 diffuse = lerp(_ShadowColor.rgb, baseColor.rgb, lightIntensity);
                diffuse *= lightColor;

                // Specular highlight (toon style)
                float3 halfVector = normalize(lightDir + viewDirWS);
                float NdotH = dot(normalWS, halfVector);
                float specular = smoothstep(1.0 - _SpecularSize - _SpecularSmoothness,
                                           1.0 - _SpecularSize + _SpecularSmoothness,
                                           NdotH);
                half3 specularColor = specular * _SpecularColor.rgb * lightColor;

                // Rim lighting
                float rimDot = 1.0 - dot(viewDirWS, normalWS);
                float rimIntensity = pow(rimDot, _RimPower);
                rimIntensity = smoothstep(0.5, 1.0, rimIntensity);
                half3 rim = rimIntensity * _RimColor.rgb * _RimIntensity;

                // Combine all lighting
                half3 finalColor = diffuse + specularColor + rim;

                // Apply fog
                finalColor = MixFog(finalColor, input.fogCoord);

                return half4(finalColor, baseColor.a);
            }
            ENDHLSL
        }

        // Shadow caster pass for toon shader
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On
            ZTest LEqual
            ColorMask 0

            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }
    }

    FallBack "Universal Render Pipeline/Lit"
}
