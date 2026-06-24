module TOGOctahedronBrowser

using TOGBroadcastBrowser: BroadcastBrowser
using TOGOctahedron: Octahedron, ∃̇
# using TOGMoveOctahedron
using TOG: ○
using TOGColor: scalar2rgba
using LoopOS: @whiletrue

function awaken(; octahedron, browser)
    octahedron.♯ = (Int(browser.width), Int(browser.height))
    BROWSER[] =
        Browser(
            octahedron,
            browserlooptask(octahedron),
            browser)
end
mutable struct Browser
    o::Octahedron
    loop::Union{Task,Nothing}
    browser::Union{BroadcastBrowser,Nothing}
end
const BROWSER = Ref{Browser}()
const OBSERVE = Ref(true)
browserlooptask(octahedron) = errormonitor(Threads.@spawn begin
    # t = time()
    put!(BroadcastBrowser, JS(octahedron.♯[1], octahedron.♯[2]))
    # # put!(browser.processor, JS(o.♯[1], o.♯[2]))
    ϕ = fill(○(first(typeof(octahedron).parameters)), octahedron.♯[1], octahedron.♯[2]), ones(first(typeof(octahedron).parameters), octahedron.♯[1], octahedron.♯[2])
    @whiletrue begin
                try
        #     #         # t̃ = time()
        #     #         # dt = t̃ - t
        #     #         # t = t̃
        #     #         # step!(o)
        # sleep(1) # DEBUG
        OBSERVE[] || continue
        ϕ̇ = Base.invokelatest() do
            ∃̇(octahedron)
        end
        #     #         # unique(ϕ̇) # DEBUG
        δ = Δ!(ϕ, ϕ̇)
        isempty(δ) && continue
        js = "pixel=" * writeδ(δ, octahedron.♯[2]) * "\n" * SET_PIXELS_JS
        #     @show "length(js)", length(js)
        put!(BroadcastBrowser, js)
                catch e
                    bt = catch_backtrace()
                    showerror(stderr, e, bt)
                    sleep(1)
                end
    end
end)

# const invϕ = one(T) / MathConstants.golden
# function godbrowserstart(port, browser)
#     # godBROWSER[].loop isa Task && schedule(godBROWSER[].loop, InterruptException(), error=true)
#     godBROWSER[].browser = browser
#     godBROWSER[].o.♯ = (Int(browser.width), Int(browser.height))
#     godBROWSER[].loop = godbrowserlooptask(godBROWSER[].g, godBROWSER[].browser)
#     @show "got godBROWSER $port, $(browser.width), $(browser.height)"
# end
# put!(::godBrowser) = nothing # todo ?
# const godBROWSER = Ref(godBrowser(
#     god(
#         t=t(),
#         d=sort(SA[invϕ, invϕ^2, one(T)]), # t, x, y, z
#         # ẑeroμ=SA[T(0.2), T(0.2), T(0.2)],
#         # ôneμ=SA[T(0.2), T(0.2), T(0.3)],
#         ẑeroμ=SA[invϕ, invϕ, invϕ],
#         ôneμ=SA[invϕ, invϕ, invϕ+T(0.01)],
#         ρ=(T(0.01), T(0.01), zero(T)),
#         ♯=(10, 10)),
#     nothing, nothing
# ))
function Δ!(ϕ, ϕ̇)
    δ = Tuple{CartesianIndex{2},Tuple{eltype(ϕ[1]),eltype(ϕ[1]),eltype(ϕ[1]),eltype(ϕ[1])}}[]
    for i = CartesianIndices(ϕ̇[1])
        ϕ[1][i] == ϕ̇[1][i] && ϕ[2][i] == ϕ̇[2][i] && continue
        ϕ[1][i] = ϕ̇[1][i]
        ϕ[2][i] = ϕ̇[2][i]
        rgba = scalar2rgba(ϕ̇[1][i], ϕ̇[2][i])
        push!(δ, (i, (eltype(ϕ[1])(rgba.r), eltype(ϕ[1])(rgba.g), eltype(ϕ[1])(rgba.b), eltype(ϕ[1])(rgba.alpha))))
    end
    δ
end
function writeδ(δ, height)
    result = []
    for (i, color) = δ
        push!(result, (i[1] - 1, height - 1 - (i[2] - 1), round.(UInt8, typemax(UInt8) .* color)...))
    end
    bracket(x) = "[" * x * "]"
    bracket(join(map(r -> bracket(join(r, ',')), result), ','))
end
const JS(width, height) = """
document.body.style.margin = '0'
document.body.style.display = 'flex'
document.body.style.justifyContent = 'center'
document.body.style.alignItems = 'center'
document.body.style.minHeight = '100vh'
canvas = document.createElement('canvas')
canvas.width = $(width)
canvas.height = $(height)
document.body.appendChild(canvas)
ctx = canvas.getContext('2d')
imageData = ctx.createImageData(canvas.width, canvas.height)
setPixel = (x, y, r, g, b, a) => {
    let i = (y * canvas.width + x) * 4
    imageData.data[i] = r
    imageData.data[i+1] = g
    imageData.data[i+2] = b
    imageData.data[i+3] = a
}
"""
const SET_PIXELS_JS = """
for (let [x,y,r,g,b,a] of pixel) setPixel(x,y,r,g,b,a)
ctx.putImageData(imageData, 0, 0)
"""

keypress(key) = @show "keypress", key
# const CHANGE_MODE = Ref(2) # 0=ρ, 1=zero, 2=focus, 3=zero+focus
# const CHANGE_DIM_INDEX = Ref(2)
# function keypress(key)
#     o = BROWSER[].o
#     if key == "ArrowUp"
#         if CHANGE_MODE[] == 0
#             scaleup!(o, CHANGE_DIM_INDEX[])
#         elseif CHANGE_MODE[] == 1
#             moveup!(o, CHANGE_DIM_INDEX[])
#         elseif CHANGE_MODE[] == 2
#             focusup!(o, CHANGE_DIM_INDEX[])
#         elseif CHANGE_MODE[] == 3
#             moveup!(o, CHANGE_DIM_INDEX[])
#             focusup!(o, CHANGE_DIM_INDEX[])
#         end
#     elseif key == "ArrowDown"
#         if CHANGE_MODE[] == 0
#             scaledown!(o, CHANGE_DIM_INDEX[])
#         elseif CHANGE_MODE[] == 1
#             movedown!(o, CHANGE_DIM_INDEX[])
#         elseif CHANGE_MODE[] == 2
#             focusdown!(o, CHANGE_DIM_INDEX[])
#         elseif CHANGE_MODE[] == 3
#             movedown!(o, CHANGE_DIM_INDEX[])
#             focusdown!(o, CHANGE_DIM_INDEX[])
#         end
#     elseif key == "0"
#         global CHANGE_MODE[] = (CHANGE_MODE[] + 1) % 4
#     elseif key == "["
#         global CHANGEΔ *= ○
#     elseif key == "]"
#         global CHANGEΔ *= T(2)
#     elseif key == "q"
#         jerkup!(o)
#     elseif key == "w"
#         jerkdown!(o)
#     elseif key == "d"
#         rotateup!(o)
#     elseif key == "f"
#         rotatedown!(o)
#     elseif key == " "
#         # put!(TOG)
#     elseif key == "t"
#         step!(o)
#     elseif key == "Backspace"
#         o.∂t₀ = !o.∂t₀
#     else
#         try
#             global CHANGE_DIM_INDEX[] = parse(UInt, key)
#         catch
#         end
#     end
#     println("key=$key")
#     println("CHANGE_MODE=$CHANGE_MODE[]")
#     println("CHANGE_DIM_INDEX=$CHANGE_DIM_INDEX[]")
#     println("ẑero.μ=$(o.ẑero.μ)")
#     println("ône.μ=$(o.ône.μ)")
#     println("o.ρ=$(o.ρ)")
#     println("o.θ=$(o.θ)")
#     println("o.∂t₀=$(o.∂t₀)")
#     println("o.v=$(o.v)")
#     println("o.norm(o.ône.μ.-o.ẑero.μ)=$(o.norm(o.ône.μ.-o.ẑero.μ))")
# end

# const BROWSER_TASK = Threads.@spawn awaken(godbrowserstart, godbrowserkeypress)

end
