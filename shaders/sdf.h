
float sdPlane( vec3 p )
{
	return p.y;
}
/*
float sdPlane( vec3 p, vec4 n ) {
	// n must be normalized
	return dot(p,n.xyz) + n.w;
}
*/

float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

float sdBox( vec3 p, vec3 b )
{
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sdEllipsoid( in vec3 p, in vec3 r )
{
    return (length( p/r ) - 1.0) * min(min(r.x,r.y),r.z);
}

float udRoundBox( vec3 p, vec3 b, float r )
{
    return length(max(abs(p)-b,0.0))-r;
}

float sdTorus( vec3 p, vec2 t )
{
    return length( vec2(length(p.xz)-t.x,p.y) )-t.y;
}

float sdHexPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
#if 0
    return max(q.z-h.y,max((q.x*0.866025+q.y*0.5),q.y)-h.x);
#else
    float d1 = q.z-h.y;
    float d2 = max((q.x*0.866025+q.y*0.5),q.y)-h.x;
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
#endif
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
	vec3 pa = p-a, ba = b-a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return length( pa - ba*h ) - r;
}

float sdEquilateralTriangle(  in vec2 p )
{
    const float k = sqrt(3.0);
    p.x = abs(p.x) - 1.0;
    p.y = p.y + 1.0/k;
    if( p.x + k*p.y > 0.0 ) p = vec2( p.x - k*p.y, -k*p.x - p.y )/2.0;
    p.x += 2.0 - 2.0*clamp( (p.x+2.0)/2.0, 0.0, 1.0 );
    return -length(p)*sign(p.y);
}

float sdTriPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
    float d1 = q.z-h.y;
#if 1
    // distance bound
    float d2 = max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5;
#else
    // correct distance
    h.x *= 0.866025;
    float d2 = sdEquilateralTriangle(p.xy/h.x)*h.x;
#endif
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}

float sdCylinder( vec3 p, vec2 h )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdCone( in vec3 p, in vec3 c )
{
    vec2 q = vec2( length(p.xz), p.y );
    float d1 = -q.y-c.z;
    float d2 = max( dot(q,c.xy), q.y);
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}

float sdConeSection( in vec3 p, in float h, in float r1, in float r2 )
{
    float d1 = -p.y - h;
    float q = p.y - h;
    float si = 0.5*(r1-r2)/h;
    float d2 = max( sqrt( dot(p.xz,p.xz)*(1.0-si*si)) + q*si - r2, q );
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}

float sdPryamid4(vec3 p, vec3 h ) // h = { cos a, sin a, height }
{
    // Tetrahedron = Octahedron - Cube
    float box = sdBox( p - vec3(0,-2.0*h.z,0), vec3(2.0*h.z) );

    float d = 0.0;
    d = max( d, abs( dot(p, vec3( -h.x, h.y, 0 )) ));
    d = max( d, abs( dot(p, vec3(  h.x, h.y, 0 )) ));
    d = max( d, abs( dot(p, vec3(  0, h.y, h.x )) ));
    d = max( d, abs( dot(p, vec3(  0, h.y,-h.x )) ));
    float octa = d - h.z;
    return max(-box,octa); // Subtraction
 }

float length2( vec2 p )
{
	return sqrt( p.x*p.x + p.y*p.y );
}

float length6( vec2 p )
{
	p = p*p*p; p = p*p;
	return pow( p.x + p.y, 1.0/6.0 );
}

float length8( vec2 p )
{
	p = p*p; p = p*p; p = p*p;
	return pow( p.x + p.y, 1.0/8.0 );
}

float sdTorus82( vec3 p, vec2 t )
{
    vec2 q = vec2(length2(p.xz)-t.x,p.y);
    return length8(q)-t.y;
}

float sdTorus88( vec3 p, vec2 t )
{
    vec2 q = vec2(length8(p.xz)-t.x,p.y);
    return length8(q)-t.y;
}

float sdCylinder6( vec3 p, vec2 h )
{
    return max( length6(p.xz)-h.x, abs(p.y)-h.y );
}

float udBox( vec3 p, vec3 b )
{
	return length(max(abs(p)-b,0.0));
}

float sdCylinder( vec3 p, vec3 c )
{
	return length(p.xz-c.xy)-c.z;
}

float sdCone( vec3 p, vec2 c )
{
	// c must be normalized
	float q = length(p.xy);
	return dot(c,vec2(q,p.z));
}

float sdCappedCylinder( vec3 p, vec2 h )
{
	vec2 d = abs(vec2(length(p.xz),p.y)) - h;
	return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdCappedCone( in vec3 p, in vec3 c )
{
	vec2 q = vec2( length(p.xz), p.y );
	vec2 v = vec2( c.z*c.y/c.x, -c.z );
	vec2 w = v - q;
	vec2 vv = vec2( dot(v,v), v.x*v.x );
	vec2 qv = vec2( dot(v,w), v.x*w.x );
	vec2 d = max(qv,0.0)*qv/vv;
	return sqrt( dot(w,w) - max(d.x,d.y) ) * sign(max(q.y*v.x-q.x*v.y,w.y));
}

float dot2( in vec3 v ) { return dot(v,v); }
float udTriangle( vec3 p, vec3 a, vec3 b, vec3 c )
{
	vec3 ba = b - a; vec3 pa = p - a;
	vec3 cb = c - b; vec3 pb = p - b;
	vec3 ac = a - c; vec3 pc = p - c;
	vec3 nor = cross( ba, ac );

	return sqrt(
	(sign(dot(cross(ba,nor),pa)) +
	sign(dot(cross(cb,nor),pb)) +
	sign(dot(cross(ac,nor),pc))<2.0)
	?
	min( min(
	dot2(ba*clamp(dot(ba,pa)/dot2(ba),0.0,1.0)-pa),
	dot2(cb*clamp(dot(cb,pb)/dot2(cb),0.0,1.0)-pb) ),
	dot2(ac*clamp(dot(ac,pc)/dot2(ac),0.0,1.0)-pc) )
	:
	dot(nor,pa)*dot(nor,pa)/dot2(nor) );
}

float udQuad( vec3 p, vec3 a, vec3 b, vec3 c, vec3 d )
{
	vec3 ba = b - a; vec3 pa = p - a;
	vec3 cb = c - b; vec3 pb = p - b;
	vec3 dc = d - c; vec3 pc = p - c;
	vec3 ad = a - d; vec3 pd = p - d;
	vec3 nor = cross( ba, ad );

	return sqrt(
	(sign(dot(cross(ba,nor),pa)) +
	sign(dot(cross(cb,nor),pb)) +
	sign(dot(cross(dc,nor),pc)) +
	sign(dot(cross(ad,nor),pd))<3.0)
	?
	min( min( min(
	dot2(ba*clamp(dot(ba,pa)/dot2(ba),0.0,1.0)-pa),
	dot2(cb*clamp(dot(cb,pb)/dot2(cb),0.0,1.0)-pb) ),
	dot2(dc*clamp(dot(dc,pc)/dot2(dc),0.0,1.0)-pc) ),
	dot2(ad*clamp(dot(ad,pd)/dot2(ad),0.0,1.0)-pd) )
	:
	dot(nor,pa)*dot(nor,pa)/dot2(nor) );
}


float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float smax( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( a, b, h ) + k*h*(1.0-h);
}


vec2 opU( vec2 d1, vec2 d2, float k )
{
	return k==0.0 ? (d1.x < d2.x ? d1 : d2) :
		vec2(smin(d1.x, d2.x, k), (d1.x < d2.x ? d1.y : d2.y));
}

vec2 opS( vec2 d1, vec2 d2, float k )
{
	return k==0.0 ? (d1.x > -d2.x ? d1 : d2) :
		vec2(smax(d1.x, -d2.x, k), (d1.x > -d2.x ? d1.y : d2.y));
}

vec2 opI( vec2 d1, vec2 d2, float k )
{
	return k==0.0 ? (d1.x > d2.x ? d1 : d2) :
		vec2(smax(d1.x, d2.x, k), (d1.x > d2.x ? d1.y : d2.y));
}


vec3 opRep( vec3 p, vec3 c )
{
	vec3 q = mod(p,c)-0.5*c;
	//return primitve( q );
	return q;
}

// invert not defined
/*
vec3 opTx( vec3 p, mat4 m )
{
	vec3 q = invert(m)*p;
	//return primitive(q);
	return q;
}
*/

/*
float opScale( vec3 p, float s )
{
	return primitive(p/s)*s;
}
*/

vec3 opTwist( vec3 p )
{
	float c = cos(20.0*p.y);
	float s = sin(20.0*p.y);
	mat2  m = mat2(c,-s,s,c);
	vec3  q = vec3(m*p.xz,p.y);
	//return primitive(q);
	return q;
}

vec3 opCheapBend( vec3 p )
{
	float c = cos(20.0*p.y);
	float s = sin(20.0*p.y);
	mat2  m = mat2(c,-s,s,c);
	vec3  q = vec3(m*p.xy,p.z);
	//return primitive(q);
	return q;
}
