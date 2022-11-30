--pieces
        --local base = piece "base"
        local smokespot = piece "base"
	--local dmgPieces = { piece "base" }
	local base = piece "base"

-- includes
	include "dmg_smoke.lua"
	include "animation.lua"


function animShadow(getid, getpiece)
	local id=getid
	local piece=getpiece
	local last_inbt = true
	local x = 0
	local y = 0
	local z = 0

	while (true) do
		local inbt = select(5,Spring.GetUnitHealth(id)) < 1
			if (inbuilt ~= last_inbt) then
				last_inbt = inbuilt
				if (inbuilt) then
					--nothing
				else
					while (true) do
						x, y, z = Spring.GetUnitPosition(unitID)
						-- local x,y,z,dx,dy,dz	= Spring.GetUnitPiecePosDir(unitID, pieceName)
						Spring.SpawnCEG("shadowsmoke", x, y+10, z)
						Sleep(200)
					end
				end
			end
		Sleep(1000)
	end


end

--Turn(luparm, y_axis,   0.125858,  3.550800 * speedMult) -- delta=6.78
--Move(pelvis, x_axis, - 2.217917, 27.582171 * speedMult) -- delta=0.92
--newIdleZ =  Rand(-1*IDLEHOVERSCALE,IDLEHOVERSCALE);
--			var IdleSpeed;
--			IdleSpeed = Rand(IDLEHOVERSPEED,IDLEHOVERSPEED*3); 
--			if (IdleSpeed < 10) IdleSpeed = 10; //wierd div by zero error?
--move IDLEBASEPIECE to x-axis [0.25]*newIdleX speed [0.25]*(newIdleX - IdleX)*30/IdleSpeed; 

function animHover(getId)
	local idle_speed = 2
	local hover_scale = 2
	local new_z = 0
	local new_speed = 0
	 
	while (true) do
		new_z = math.random(-1*hover_scale, hover_scale)
		new_speed = math.random(idle_speed, idle_speed *2)
 		
		Move(base,y_axis, new_z, new_speed)
		Sleep(500)
	end

end

function script.Create()
	--StartThread(animShadow, unitID, smokespot)
	--StartThread(animHover, unitID)
	
end


function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	if (severity <= .25) then
		Explode(base, SFX.NONE + SFX.NO_HEATCLOUD)
		return 1 -- corpsetype

	elseif (severity <= .5) then
		Explode(base, SFX.NONE + SFX.NO_HEATCLOUD)
		return 2 -- corpsetype
	else
		Explode(base, SFX.NONE + SFX.NO_HEATCLOUD)
		return 3 -- corpsetype
	end
end