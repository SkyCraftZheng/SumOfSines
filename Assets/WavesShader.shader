// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Waves Shader"
{
    Properties {
        _Tint ("Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Albedo", 2D) = "white" {}
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5
        [Gamma] _Metallic ("Metallic", Range(0, 1)) = 0
        _NumberOfWaves("Number of Waves", Integer) = 32
        _Seed ("Seed", Vector) = (0, 0, 0, 0) //xy is the seed, zw is the iterator
        _StartingAmplitude ("Starting Amplitude", Range(0.1, 5)) = 1
        _AmplitudeFactor ("Amplitude Factor", Range(0, 1)) = 0.82
        _StartingFrequency ("Starting Frequency", Range(0.1, 5)) = 1
        _FrequencyFactor ("Frequency Factor", Range(1, 2)) = 1.18
        _StartingSpeed ("Starting Speed", Range(1, 100)) = 5
        _SpeedRamp ("Speed Ramp", Range(1, 2)) = 1.07
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

            float _NumberOfWaves;
            float4 _Seed;
            float _StartingAmplitude, _AmplitudeFactor;
            float _StartingFrequency, _FrequencyFactor;
            float _StartingSpeed, _SpeedRamp;

            struct Interpolators {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 normal : NORMAL;
            };

            struct VertexData {
                float4 position : POSITION;
                float2 uv : TEXCOORD0;
            };

            float RandomRange_float(float2 Seed, float Min, float Max){
                float randomno =  frac(sin(dot(Seed, float2(23.14069263277926, 2.665144142690225)))*43758.5453);
                return lerp(Min, Max, randomno);
            }

            Interpolators MyVertexProgram(VertexData v) {
                /*
                float _SineAmplitudes[5]  = {0.21, 0.15, 0.11, 0.17, 0.09};
                float _SineFrequencies[5] = {1, 2, 3, 1.3, 2.1};
                float _SineSpeeds[5] = {30, 40, 50, 34, 42};
                float3 _SineDirections[5] = {
                    float3(1,0,0),
                    normalize(float3(0.5, 0, 0.5)),
                    normalize(float3(-0.8, 0, 0.2)),
                    normalize(float3(0.1, 0 , 0.9)),
                    normalize(float3(0.3, 0, -0.7))};
                    */

                Interpolators i;
                float3 position = mul(unity_ObjectToWorld, v.position).xyz;
                float df, dfdx, dfdz, inner;
                dfdx = 0;
                dfdz = 0;
                float4 seed = _Seed;
                float amp = _StartingAmplitude;
                float freq = _StartingFrequency;
                float speed = _StartingSpeed;
                float displacement = - amp * _NumberOfWaves / 15;
                float angle;
                float2 direction;
                for(int j = 0; j < _NumberOfWaves; ++j){
                    // y = alpha * sin(d*(x,z) + t*phi)
                    /*
                    displacement += _SineAmplitudes[j] * sin(
                        dot(_SineDirections[j], position.xyz) * _SineFrequencies[j] + _Time * _SineSpeeds[j]);
                    */
                    // y = alpha * e^(sin(d*(x,z) + t*phi)-1)
                    /*
                    displacement += _SineAmplitudes[j] * pow(2.718282, sin(
                        dot(_SineDirections[j], position.xyz) * _SineFrequencies[j] + _Time * _SineSpeeds[j]
                    ) - 1);
                    */

                    // Brownian motion
                    angle = RandomRange_float(seed.xy, 0, 360);
                    direction = float2(sin(angle), cos(angle));
                    seed += float4(seed.zw, 0, 0);
                    inner = dot(direction, position.xz + float2(dfdx, dfdz)) * freq + _Time * speed;
                    displacement += amp * pow(2.7818282, sin(inner) - 1);
                    df = freq * amp * pow(2.7818282, sin(inner) - 1) * cos(inner);
                    amp *= _AmplitudeFactor;
                    freq *= _FrequencyFactor;
                    speed *= _SpeedRamp;

                    dfdx += df * direction.x;
                    dfdz += df * direction.y; 
                }
                position.y += displacement;
                i.worldPos = position;
                i.normal = normalize(float3(-dfdx, 1, -dfdz));
                position = mul(unity_WorldToObject, position);
                i.position = UnityObjectToClipPos(position);
                i.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return i;
            }

            float4 MyFragmentProgram(Interpolators i) : SV_TARGET {
                /*
                float _SineAmplitudes[5]  = {0.21, 0.15, 0.11, 0.17, 0.09};
                float _SineFrequencies[5] = {1, 2, 3, 1.3, 2.1};
                float _SineSpeeds[5] = {30, 40, 50, 34, 42};
                float3 _SineDirections[5] = {
                    float3(1,0,0),
                    normalize(float3(0.5, 0, 0.5)),
                    normalize(float3(-0.8, 0, 0.2)),
                    normalize(float3(0.1, 0 , 0.9)),
                    normalize(float3(0.3, 0, -0.7))};
                float df, dfdx, dfdz, inner;
                dfdx = 0;
                dfdz = 0;
                float4 seed = _Seed;
                float amp = _StartingAmplitude;
                float freq = _StartingFrequency;
                float speed = _StartingSpeed;
                float displacement = 0;
                float angle;
                float2 direction;
                for(int j = 0; j < _NumberOfWaves; ++j){
                    // inner = dot(_SineDirections[j], i.worldPos) * _SineFrequencies[j] + _Time * _SineSpeeds[j];
                    // y' for simple sin wave
                    // df = _SineFrequencies[j] * _SineAmplitudes[j] * cos(inner);
                    // y' for e^sin
                    // df = _SineFrequencies[j] * _SineAmplitudes[j] * pow(2.718282, sin(inner) - 1) * cos(inner);

                    // Brownian motion
                    angle = RandomRange_float(seed.xy, 0, 360);
                    direction = float2(sin(angle), cos(angle));
                    seed += float4(seed.zw, 0, 0);
                    inner = dot(direction, i.worldPos.xz) * freq + _Time * speed;
                    df = freq * amp * pow(2.7818282, sin(inner) - 1) * cos(inner);
                    amp *= _AmplitudeFactor;
                    freq *= _FrequencyFactor;
                    speed *= _SpeedRamp;

                    dfdx += df * direction.x; //_SineDirections[j].x * df;
                    dfdz += df * direction.y; //_SineDirections[j].z * df;
                }

                float3 normal = normalize(float3(-dfdx, 1, -dfdz));
                */
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
