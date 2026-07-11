((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,B,C={cBt:function cBt(){},inQ:function inQ(){},awg:function awg(d,e){this.a=d
this.b=e},HU:function HU(){}}
J=c[1]
A=c[0]
B=c[2]
C=a.updateHolder(c[1641],C)
C.cBt.prototype={
sbLN(d){var x,w,v=this
v.aVP$=d
if(d.length!==0){x=v.AT$
if(x!=null)x.gw_().tabIndex=-1
w=B.c.gaH(d).gdkh()
if(w!==!1)B.c.gaH(d).gw_().tabIndex=0
v.AT$=B.c.gaH(d)}w=A.a([],y.b)
v.nC$=w
w.push(new C.awg(d,0))},
CH(d,e){if(e!=null)this.dIk(e)
if(this.AT$!=null)this.U2()},
e1(d){return this.CH(0,null)},
dIk(d){var x,w,v,u,t,s,r=this,q=J.bT(d)
if(q.gaU(d))return
x=r.nC$
x===$&&A.o()
B.c.aX(x)
w=q.E(d,0)
x=r.nC$
v=r.aVP$
v===$&&A.o()
x.push(new C.awg(v,B.c.eo(v,w)))
for(u=1;u<q.gav(d);++u){r.nC$.push(new C.awg(w.gW1(w),B.c.eo(w.gW1(w),q.E(d,u))))
w=q.E(d,u)}t=r.AT$
if(t!=null)t.gw_().tabIndex=-1
q=B.c.gbB(r.nC$)
x=q.a
q=q.b
if(!(q>=0&&q<x.length))return A.G(x,q)
s=x[q]
r.AT$=s
s.gw_().tabIndex=0},
bzt(d){var x,w,v,u,t,s,r=this,q=r.AT$
if(q==null)q=r.U2()
switch(d.keyCode){case 37:d.stopPropagation()
d.preventDefault()
if(q.gaXr()&&q.gex())r.AT$.LQ(0)
else{x=r.nC$
x===$&&A.o()
if(x.length>1){x.pop()
r.U2()}}break
case 39:d.stopPropagation()
d.preventDefault()
if(q.gaXr())if(q.gex())r.cuG()
else q.Qu(0)
break
case 40:d.stopPropagation()
d.preventDefault()
r.cuG()
break
case 38:d.stopPropagation()
d.preventDefault()
r.ekU()
break
case 32:case 13:d.stopPropagation()
d.preventDefault()
q.b23()
break
case 36:d.stopPropagation()
d.preventDefault()
x=r.nC$
x===$&&A.o()
B.c.lX(x,1,x.length)
B.c.gbB(r.nC$).b=0
r.U2()
break
case 35:d.stopPropagation()
d.preventDefault()
x=r.nC$
x===$&&A.o()
w=x.length
v=0
for(;v<w;++v){u=x[v]
t=u.b
s=u.a.length-1
if(t!==s){u.b=s
x=r.nC$
w=v+1
u=x.length
x.$flags&1&&A.fA(x,18)
A.nm(w,u,u)
x.splice(w,u-w)
break}}r.cHu()
r.U2()
break}},
U2(){var x,w,v,u=this.AT$
if(u!=null)u.gw_().tabIndex=-1
x=this.nC$
x===$&&A.o()
x=B.c.gbB(x)
w=x.a
x=x.b
if(!(x>=0&&x<w.length))return A.G(w,x)
v=this.AT$=w[x]
v.gw_().tabIndex=0
v.gw_().focus()
return v},
cuG(){var x,w,v,u,t=this
if(t.geLp())return
x=t.nC$
x===$&&A.o()
x=B.c.gbB(x)
w=x.a
v=x.b
if(!(v>=0&&v<w.length))return A.G(w,v)
if(w[v].gn0()){x=x.b
if(!(x>=0&&x<w.length))return A.G(w,x)
x=w[x].gex()}else x=!1
if(x){u=t.AT$
if(u!=null)t.nC$.push(new C.awg(u.gW1(u),0))}else{while(x=B.c.gbB(t.nC$),x.b===x.a.length-1){x=t.nC$
if(0>=x.length)return A.G(x,-1)
x.pop()}x=B.c.gbB(t.nC$)
w=x.b
v=x.a.length
if(w>=v-1)A.ae(A.b4("Failed precondition: _index="+w+" nodes.length="+v))
x.b=w+1}t.U2()},
ekU(){var x,w=this,v=w.nC$
v===$&&A.o()
if(v.length===1&&B.c.gbB(v).b===0)return
v=B.c.gbB(w.nC$).b
x=w.nC$
if(v===0){if(0>=x.length)return A.G(x,-1)
x.pop()}else{v=B.c.gbB(x)
x=v.b
if(x<=0)A.ae(A.b4("Failed precondition: _index="+x))
v.b=x-1
w.cHu()}w.U2()},
cHu(){var x,w,v,u
for(;;){x=this.nC$
x===$&&A.o()
x=B.c.gbB(x)
w=x.a
v=x.b
if(!(v>=0&&v<w.length))return A.G(w,v)
if(w[v].gn0()){x=x.b
if(!(x>=0&&x<w.length))return A.G(w,x)
x=w[x].gex()}else x=!1
if(!x)break
x=B.c.gbB(this.nC$)
w=x.a
x=x.b
if(!(x>=0&&x<w.length))return A.G(w,x)
x=w[x]
u=x.gW1(x)
this.nC$.push(new C.awg(u,u.length-1))}},
geLp(){var x,w,v=this.nC$
v===$&&A.o()
v=B.c.gbB(v)
x=v.a
w=v.b
if(!(w>=0&&w<x.length))return A.G(x,w)
if(x[w].gn0()){v=v.b
if(!(v>=0&&v<x.length))return A.G(x,v)
v=x[v].gex()}else v=!1
return!v&&B.c.dt(this.nC$,new C.inQ())}}
C.awg.prototype={}
C.HU.prototype={
gdkh(){return null},
gaXr(){return this.gn0()}}
var z=a.updateTypes(["~([O<HU>?])","I(awg)"])
C.inQ.prototype={
$1(d){return d.b===d.a.length-1},
$S:z+1};(function installTearOffs(){var x=a.installInstanceTearOff
x(C.cBt.prototype,"gtE",1,0,function(){return[null]},["$1","$0"],["CH","e1"],0,0,0)})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(A.B,[C.cBt,C.awg,C.HU])
w(C.inQ,A.aK)})()
var y={b:A.q("t<awg>")}};
(a=>{a["i3RmSOX2ImNQLOmBe3y7Y1LDCX0="]=a.current})($__dart_deferred_initializers__);
//# sourceMappingURL=main.dart.js_1099.part.js.map
