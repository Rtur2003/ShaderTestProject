Shader "Lit/PulsingLight"
{
    Properties
    {
        [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _Tiling ("Tiling",Range(1,64))=1
        _Power("Power",Range(0,128))=1
        _PulseSpeed("PulseSpeed",Range(0,16))=2
        _CustomLightColor("Custom Light Color",Color)=(1,1,1,1)
        
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        
        Pass
        {
            Tags {"LightMode"="UniversalForward"}
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
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
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float _Tiling;
            float _Power;
            float _PulseSpeed;
            float pulseAmount;
            float4 _CustomLightColor;
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _BaseColor;
            CBUFFER_END

            
            float AnimatedPower()
            {
                float pulse=sin(_Time.y*_PulseSpeed);
                pulse=(pulse+1.0)*.5;
                pulse=smoothstep(0.0,1.0,pulse)*smoothstep(1.0,0.0,pulse);
                return pulse*_Power;
            }
            
            Varyings vert (Attributes input)
            {
                Varyings output;
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                return output;
            }
            
            half4 frag (Varyings input) : SV_Target
            {
                // Sample texture
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv*_Tiling);
                col *= _BaseColor;
                
                // Get main light
                Light mainLight = GetMainLight();
                pulseAmount=AnimatedPower();
                float4 color=_CustomLightColor;
                float3 lightColor =color*pulseAmount;
                float3 lightDir = mainLight.direction;
                
                // Diffuse lighting (N dot L)
                float ndotl = max(0, dot(input.normalWS, lightDir));
                half3 diffuse = ndotl * lightColor;
                
                // Ambient lighting (URP style)
                half3 ambient = SampleSH(input.normalWS);
                
                // Combine
                col.rgb *= (diffuse + ambient);
                
                return col;
            }
            ENDHLSL
        }
    }
}