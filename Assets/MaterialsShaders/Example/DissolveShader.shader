/*
 * Dissolve Shader
 *
 * Purpose: Animated material disintegration/burn effect
 * Use Case: VFX, enemy deaths, teleportation, power-ups
 * Performance: Medium (noise texture sampling, alpha clipping)
 *
 * Features:
 * - Noise-based dissolve pattern
 * - Customizable burn edge color
 * - Animated edge glow
 * - Adjustable dissolve amount
 * - Alpha cutoff for clean edges
 *
 * Learning: Texture-based effects, alpha cutoff, VFX techniques
 */

Shader "URP/DissolveShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1, 1, 1, 1)

        [Header(Dissolve Settings)]
        _DissolveTex ("Dissolve Noise", 2D) = "white" {}
        _DissolveAmount ("Dissolve Amount", Range(0, 1)) = 0.5
        _DissolveEdgeWidth ("Edge Width", Range(0, 0.2)) = 0.05

        [Header(Edge Glow)]
        _EdgeColor1 ("Edge Color 1", Color) = (1, 0.5, 0, 1)
        _EdgeColor2 ("Edge Color 2", Color) = (1, 0, 0, 1)
        _EdgeEmission ("Edge Emission", Range(0, 10)) = 2
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "TransparentCutout"
            "Queue" = "AlphaTest"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            Cull Off

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
                float2 dissolveUV : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 positionWS : TEXCOORD3;
                float fogCoord : TEXCOORD4;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            TEXTURE2D(_DissolveTex);
            SAMPLER(sampler_DissolveTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _DissolveTex_ST;
                half4 _Color;
                float _DissolveAmount;
                float _DissolveEdgeWidth;
                half4 _EdgeColor1;
                half4 _EdgeColor2;
                float _EdgeEmission;
            CBUFFER_END

            Varyings vert (Attributes input)
            {
                Varyings output;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);

                output.positionHCS = positionInputs.positionCS;
                output.positionWS = positionInputs.positionWS;
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                output.dissolveUV = TRANSFORM_TEX(input.uv, _DissolveTex);
                output.normalWS = normalInputs.normalWS;
                output.fogCoord = ComputeFogFactor(positionInputs.positionCS.z);

                return output;
            }

            half4 frag (Varyings input) : SV_Target
            {
                // Sample textures
                half4 baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv) * _Color;
                float dissolveNoise = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, input.dissolveUV).r;

                // Calculate dissolve cutoff
                float dissolveThreshold = _DissolveAmount;
                float dissolveDelta = dissolveNoise - dissolveThreshold;

                // Discard pixels based on dissolve
                clip(dissolveDelta);

                // Calculate edge glow
                float edgeFactor = saturate(dissolveDelta / _DissolveEdgeWidth);
                half3 edgeColor = lerp(_EdgeColor2.rgb, _EdgeColor1.rgb, edgeFactor);
                half3 edgeGlow = edgeColor * _EdgeEmission * (1.0 - edgeFactor);

                // Basic lighting
                Light mainLight = GetMainLight();
                float3 normalWS = normalize(input.normalWS);
                float NdotL = max(0, dot(normalWS, mainLight.direction));
                half3 lighting = NdotL * mainLight.color + half3(0.2, 0.2, 0.2); // ambient

                // Combine base color with lighting
                half3 finalColor = baseColor.rgb * lighting;

                // Add edge glow (emissive)
                finalColor += edgeGlow;

                // Apply fog
                finalColor = MixFog(finalColor, input.fogCoord);

                return half4(finalColor, baseColor.a);
            }
            ENDHLSL
        }

        // Shadow caster pass
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
