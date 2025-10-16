/*
 * Hologram Shader
 *
 * Purpose: Sci-fi holographic projection effect
 * Use Case: Futuristic UI, holograms, force fields, sci-fi games
 * Performance: Medium (scanlines, fresnel, animation)
 *
 * Features:
 * - Animated scanline effect
 * - Fresnel rim lighting
 * - Glitch/flicker animation
 * - Adjustable transparency
 * - Additive blending for glow
 * - Color customization
 *
 * Learning: Transparency, additive blending, procedural animation
 */

Shader "URP/HologramShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _HologramColor ("Hologram Color", Color) = (0, 1, 1, 1)

        [Header(Fresnel)]
        _FresnelPower ("Fresnel Power", Range(0, 10)) = 3
        _FresnelIntensity ("Fresnel Intensity", Range(0, 5)) = 2

        [Header(Scanlines)]
        _ScanlineSpeed ("Scanline Speed", Range(0, 10)) = 2
        _ScanlineFrequency ("Scanline Frequency", Range(1, 100)) = 20
        _ScanlineWidth ("Scanline Width", Range(0, 1)) = 0.5

        [Header(Glitch Effect)]
        _GlitchSpeed ("Glitch Speed", Range(0, 20)) = 5
        _GlitchIntensity ("Glitch Intensity", Range(0, 1)) = 0.1

        [Header(Transparency)]
        _Alpha ("Alpha", Range(0, 1)) = 0.5
        _RimAlpha ("Rim Alpha", Range(0, 1)) = 0.8
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

            Blend SrcAlpha One // Additive blending for hologram glow
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

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
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                half4 _HologramColor;
                float _FresnelPower;
                float _FresnelIntensity;
                float _ScanlineSpeed;
                float _ScanlineFrequency;
                float _ScanlineWidth;
                float _GlitchSpeed;
                float _GlitchIntensity;
                float _Alpha;
                float _RimAlpha;
            CBUFFER_END

            // Simple noise function for glitch
            float Noise(float2 uv)
            {
                return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
            }

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

                return output;
            }

            half4 frag (Varyings input) : SV_Target
            {
                // Sample texture
                half4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);

                // Normalize vectors
                float3 normalWS = normalize(input.normalWS);
                float3 viewDirWS = normalize(input.viewDirWS);

                // Fresnel effect (edge glow)
                float fresnel = pow(1.0 - saturate(dot(normalWS, viewDirWS)), _FresnelPower);
                fresnel *= _FresnelIntensity;

                // Scanlines (moving horizontal lines)
                float scanline = sin((input.positionWS.y + _Time.y * _ScanlineSpeed) * _ScanlineFrequency);
                scanline = smoothstep(1.0 - _ScanlineWidth, 1.0, scanline);

                // Glitch effect (random flickering)
                float glitchNoise = Noise(float2(_Time.y * _GlitchSpeed, 0));
                float glitch = step(1.0 - _GlitchIntensity, glitchNoise);

                // Combine effects
                half3 hologramColor = _HologramColor.rgb * texColor.rgb;
                hologramColor += fresnel * _HologramColor.rgb;
                hologramColor += scanline * 0.3;
                hologramColor *= (1.0 - glitch * 0.5); // Flicker

                // Alpha calculation
                float alpha = _Alpha;
                alpha += fresnel * _RimAlpha;
                alpha += scanline * 0.2;
                alpha *= (1.0 - glitch * 0.3); // Alpha flicker

                return half4(hologramColor, alpha);
            }
            ENDHLSL
        }
    }

    FallBack "Universal Render Pipeline/Unlit"
}
