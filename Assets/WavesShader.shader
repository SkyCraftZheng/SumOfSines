// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Waves Shader"
{
    Properties {
        _Tint ("Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Albedo", 2D) = "white" {}
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5
        [Gamma] _Metallic ("Metallic", Range(0, 1)) = 0
    }

    SubShader {
        Pass {
            Tags {
				"LightMode" = "ForwardBase"
			}

            CGPROGRAM
            #pragma target 3.0

            #pragma vertex MyVertexProgram
            #pragma fragment MyFragmentProgram

            #include "UnityPBSLighting.cginc"

            float4 _Tint;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Smoothness;
            float _Metallic;

            struct Interpolators {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 worldPos : TEXCOORD1;
            };

            struct VertexData {
                float4 position : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            Interpolators MyVertexProgram(VertexData v) {
                float _SineAmplitudes[5]  = {0.4, 0.2, 0.1, 0.05, 0.025};
                float _SineFrequencies[5] = {1, 2, 3, 4, 5};
                float _SineSpeeds[5] = {30, 40, 50, 60, 70};

                Interpolators i;
                i.position = UnityObjectToClipPos(v.position);
                float displacement = 0;
                for(int j = 0; j < 5; ++j){
                    displacement += _SineAmplitudes[j] * sin(i.position.x * _SineFrequencies[j] + _Time * _SineSpeeds[j]);
                }
                i.position.y += displacement;
                i.uv = TRANSFORM_TEX(v.uv, _MainTex);
                i.normal = UnityObjectToWorldNormal(v.normal);
                i.normal = normalize(i.normal);
                i.worldPos = mul(unity_ObjectToWorld, v.position);
                return i;
            }

            float4 MyFragmentProgram(Interpolators i) : SV_TARGET {
                i.normal = normalize(i.normal);
                float3 lightDir = _WorldSpaceLightPos0.xyz;
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 lightColor = _LightColor0.rgb;

                UnityLight light;
				light.color = lightColor;
				light.dir = lightDir;
				light.ndotl = DotClamped(i.normal, lightDir);
                UnityIndirect indirectLight;
				indirectLight.diffuse = 0;
				indirectLight.specular = 0;

                float3 albedo = tex2D(_MainTex, i.uv).rgb * _Tint.rgb;
                float3 specularTint;
                float oneMinusReflectivity;
                albedo = DiffuseAndSpecularFromMetallic(
					albedo, _Metallic, specularTint, oneMinusReflectivity
				);
                return UNITY_BRDF_PBS(
					albedo, specularTint,
					oneMinusReflectivity, _Smoothness,
					i.normal, viewDir,
                    light, indirectLight
				);
            }

            ENDCG
        }
    }
}
