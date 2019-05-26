//======================================
// code by Janril
//======================================
texture2D ScreenTexture:POSTEFFECTTEXTURE;
sampler2D ScreenTextureSampler = sampler_state {
    texture = <ScreenTexture>;
    AddressU  = BORDER;
    AddressV = BORDER;
    Filter = MIN_MAG_LINEAR_MIP_POINT;
};

float4 screen : SCREENSIZE;

//���shader����չ�����ջط���������
//�ⲿ����
//����һ���Ҷ�ͼ��Ϊ�߶�ͼ�����ڸ߶Ȳ����Ĳ��ֻ���������ʾ
float height < string binding = "h"; >; //�߶�
float border_width < string binding = "wid"; >;//��߿��
float4 border_color < string binding = "col"; >;//�����ɫ
float4 border_color2 < string binding = "col2"; >;//�����ɫ2
texture2D Texture2 < string binding = "tex"; >; //�߶�ͼ
sampler2D ScreenTextureSampler2 = sampler_state {
    texture = <Texture2>;
    AddressU = BORDER;
    AddressV = BORDER;
    Filter = MIN_MAG_LINEAR_MIP_POINT;
};

float4 PS_MainPass(float4 position:POSITION, float2 uv:TEXCOORD0):COLOR
{
    float4 texColor = tex2D(ScreenTextureSampler, uv);
	float4 texColor2 = tex2D(ScreenTextureSampler2, uv);
	
	float texh = (texColor2.r + texColor2.g + texColor2.b) / 3.0 * 255.0;
	float border_brightness = 0.0;
	float4 blend_color = float4(0.0,0.0,0.0,0.0);
	//texColor.a = min(255.0, texh);
	
	if (texh <= height) {
		texColor.a = 255.0; 
		border_brightness = 1.0 + (border_width - min(border_width, (height - texh))) / border_width;
		blend_color.rgb = border_color.rgb * (border_brightness - 1.0) + border_color2.rgb * (1.0 - (border_brightness - 1.0));
		// texColor.rgb = texColor.rgb * border_brightness + blend_color.rgb * 0.5 * (border_brightness -1);
		texColor.rgb = texColor.rgb + blend_color.rgb * (border_brightness -1);
	}
	else texColor.a = 0.0f;
    return texColor;
}

technique Main
{
    pass MainPass
    {
        PixelShader = compile ps_3_0 PS_MainPass();
    }
}
