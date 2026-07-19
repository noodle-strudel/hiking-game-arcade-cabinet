// reference: https://www.youtube.com/watch?v=dMzXXqO8kWw

shader_type canvas_item;

uniform sampler2D mask;

void fragment() {
	COLOR = texture(TEXTURE, UV);
	
	vec2 muv = UV;
	
	// opacity is controlled by mask's red channel
	COLOR.a = texture(mask, muv).r;
}
