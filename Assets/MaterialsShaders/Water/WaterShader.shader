Shader "Custom/WaterShader"
{
    Properties
    {
        _ShallowColor ("Shallow Water Color", Color) = (0.1, 0.3, 0.5, 1)
        _DeepColor ("Deep Water Color", Color) = (0.02, 0.1, 0.2, 1)
        _FoamColor ("Foam Color", Color) = (1,1,1,1)
        _EdgeFoamColor ("Edge Foam Color", Color) = (0.8,0.9,1,1)
        
        _NormalTex1 ("Normal Map 1", 2D) = "bump" {}
        _NormalTex2 ("Normal Map 2", 2D) = "bump" {}
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _FoamTex ("Foam Texture", 2D) = "white" {}
        
        _WaveSpeed ("Wave Speed", Range(0, 2)) = 0.5
        _WaveStrength ("Wave Strength", Range(0, 0.1)) = 0.03
        _WaveFrequency ("Wave Frequency", Range(0, 5)) = 1.0
        
        _NormalStrength ("Normal Strength", Range(0, 2)) = 0.5
        _NormalSpeed ("Normal Speed", Range(0, 2)) = 0.3
        
        _Depth ("Depth", Range(0, 10)) = 2.0
        _Transparency ("Transparency", Range(0, 1)) = 0.8
        
        _FoamAmount ("Foam Amount", Range(0, 1)) = 0.3
        _FoamSpeed ("Foam Speed", Range(0, 2)) = 0.2
        _FoamCutoff ("Foam Cutoff", Range(0, 1)) = 0.4
        
        _EdgeFoamWidth ("Edge Foam Width", Range(0, 2)) = 0.5
        _EdgeFoamIntensity ("Edge Foam Intensity", Range(0, 5)) = 1.0
        
        _SpecularPower ("Specular Power", Range(1, 100)) = 50
        _SpecularIntensity ("Specular Intensity", Range(0, 5)) = 1.0
        
        _CausticsTex ("Caustics Texture", 2D) = "white" {}
        _CausticsSpeed ("Caustics Speed", Range(0, 1)) = 0.2
        _CausticsIntensity ("Caustics Intensity", Range(0, 2)) = 0.5
    }
    
    SubShader
    {
        Tags 
        { 
            "RenderType" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Transparent"
            "ForceNoShadowCasting" = "True"
        }
        
        LOD 300

        Pass
        {
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" }
            
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite On
            Cull Back
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
                float3 normalWS : TEXCOORD3;
                float3 viewDirWS : TEXCOORD4;
                float fogCoord : TEXCOORD5;
                float eyeDepth : TEXCOORD6;
            };

            // Texture Properties - URP stili
            TEXTURE2D(_NormalTex1);
            TEXTURE2D(_NormalTex2);
            TEXTURE2D(_NoiseTex);
            TEXTURE2D(_FoamTex);
            TEXTURE2D(_CausticsTex);

            SAMPLER(sampler_NormalTex1);
            SAMPLER(sampler_NormalTex2);
            SAMPLER(sampler_NoiseTex);
            SAMPLER(sampler_FoamTex);
            SAMPLER(sampler_CausticsTex);

            CBUFFER_START(UnityPerMaterial)
                // Renkler
                float4 _ShallowColor;
                float4 _DeepColor;
                float4 _FoamColor;
                float4 _EdgeFoamColor;
                
                // Texture scale/offset
                float4 _NormalTex1_ST;
                float4 _NormalTex2_ST;
                float4 _NoiseTex_ST;
                float4 _FoamTex_ST;
                float4 _CausticsTex_ST;
                
                // Wave
                float _WaveSpeed;
                float _WaveStrength;
                float _WaveFrequency;
                
                // Normal
                float _NormalStrength;
                float _NormalSpeed;
                
                // Transparency
                float _Depth;
                float _Transparency;
                
                // Foam
                float _FoamAmount;
                float _FoamSpeed;
                float _FoamCutoff;
                
                // Edge foam
                float _EdgeFoamWidth;
                float _EdgeFoamIntensity;
                
                // Specular
                float _SpecularPower;
                float _SpecularIntensity;
                
                // Caustics
                float _CausticsSpeed;
                float _CausticsIntensity;
            CBUFFER_END

            float3 Wave(float3 position, float2 uv, float time)
            {
                float wave1 = sin(uv.x * _WaveFrequency + time * _WaveSpeed) * _WaveStrength;
                float wave2 = cos(uv.y * _WaveFrequency * 0.7 + time * _WaveSpeed * 1.3) * _WaveStrength * 0.7;
                float wave3 = sin((uv.x + uv.y) * _WaveFrequency * 1.5 + time * _WaveSpeed * 0.7) * _WaveStrength * 0.5;
                
                return float3(0, wave1 + wave2 + wave3, 0);
            }

            Varyings vert(Attributes input)
            {
                Varyings output;
                
                float3 waveOffset = Wave(input.positionOS.xyz, input.texcoord, _Time.y);
                input.positionOS.xyz += waveOffset;
                
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                
                output.positionCS = positionInputs.positionCS;
                output.positionWS = positionInputs.positionWS;
                output.uv = input.texcoord;
                output.screenPos = positionInputs.positionNDC;
                output.normalWS = normalInputs.normalWS;
                output.viewDirWS = GetWorldSpaceNormalizeViewDir(positionInputs.positionWS);
                output.fogCoord = ComputeFogFactor(output.positionCS.z);
                output.eyeDepth = -positionInputs.positionVS.z; // Düzeltildi
                
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float2 screenUV = input.screenPos.xy / input.screenPos.w;
                float rawDepth = SampleSceneDepth(screenUV);
                float sceneDepth = LinearEyeDepth(rawDepth, _ZBufferParams);
                float surfaceDepth = sceneDepth - input.eyeDepth;
                
                float depthFactor = saturate(surfaceDepth / _Depth);
                half3 waterColor = lerp(_ShallowColor.rgb, _DeepColor.rgb, depthFactor);
                
                float2 normalUV1 = input.uv * _NormalTex1_ST.xy + _Time.y * _NormalSpeed * float2(0.1, 0.2);
                float2 normalUV2 = input.uv * _NormalTex2_ST.xy + _Time.y * _NormalSpeed * float2(-0.15, 0.1);
                
                half3 normal1 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex1, sampler_NormalTex1, normalUV1));
                half3 normal2 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex2, sampler_NormalTex2, normalUV2));
                half3 combinedNormal = normalize(lerp(half3(0, 0, 1), normal1 + normal2, _NormalStrength));
                
                float2 foamUV = input.uv * _FoamTex_ST.xy + _Time.y * _FoamSpeed;
                half foamPattern = SAMPLE_TEXTURE2D(_FoamTex, sampler_FoamTex, foamUV).r;
                half foam = saturate(foamPattern - _FoamCutoff + _FoamAmount);
                foam *= (1.0 - depthFactor);
                
             
                half edgeFoam = saturate((1.0 - depthFactor) * _EdgeFoamIntensity);
                edgeFoam = pow(edgeFoam, _EdgeFoamWidth);
                
                // Caustics 
                float2 causticsUV = input.uv * _CausticsTex_ST.xy + _Time.y * _CausticsSpeed;
                half caustics = SAMPLE_TEXTURE2D(_CausticsTex, sampler_CausticsTex, causticsUV).r;
                waterColor += caustics * _CausticsIntensity * (1.0 - depthFactor);
                
                // Işık hesaplamaları
                Light mainLight = GetMainLight();
                float3 lightDir = mainLight.direction;
                float3 viewDir = normalize(input.viewDirWS);
                
                // Specular (parlaklık)
                float3 halfVector = normalize(lightDir + viewDir);
                float specular = pow(saturate(dot(combinedNormal, halfVector)), _SpecularPower) * _SpecularIntensity;
                
                // Fresnel efekti (açıya göre şeffaflık)
                float fresnel = pow(1.0 - saturate(dot(combinedNormal, viewDir)), 3.0);
                
                // Final renk kompozisyonu
                half3 finalColor = waterColor;
                finalColor = lerp(finalColor, _FoamColor.rgb, foam);
                finalColor = lerp(finalColor, _EdgeFoamColor.rgb, edgeFoam);
                finalColor += specular * mainLight.color * 0.5;
                
                // Şeffaflık
                half alpha = _Transparency;
                alpha = lerp(alpha, 1.0, saturate(foam + edgeFoam)); // Foam'lar opak
                alpha *= saturate(depthFactor * 2.0); // Derinlikle şeffaflık
                alpha *= fresnel; // Fresnel etkisi
                
                // Fog
                finalColor = MixFog(finalColor, input.fogCoord);
                
                return half4(finalColor, alpha);
            }
            ENDHLSL
        }
    }
    
    FallBack "Universal Render Pipeline/Unlit"
}