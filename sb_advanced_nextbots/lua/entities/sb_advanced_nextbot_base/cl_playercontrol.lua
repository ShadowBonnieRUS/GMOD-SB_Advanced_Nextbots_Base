
--[[------------------------------------
	Name: NEXTBOT:ModifyPlayerControlHUD
	Desc: Allows modify HUD with bot's info.
	Arg1: number | x | X HUD coordinate.
	Arg2: number | y | Y HUD coordinate.
	Arg3: number | w | Width of health bar.
	Arg4: number | h | Height of health bar.
	Ret1: bool | Return true to prevent drawing default HUD.
--]]------------------------------------
function ENT:ModifyPlayerControlHUD(x,y,w,h)
	return self:RunTask("ModifyPlayerControlHUD",x,y,w,h)
end

local function GetControlledBot()
	local bot = LocalPlayer():GetDrivingEntity()
	
	if IsValid(bot) and bot.SBAdvancedNextBot then
		return bot
	end
end

--[[------------------------------------
	GM:HUDPaint
	Draw info about controlled bot
--]]------------------------------------
hook.Add("HUDPaint","SBAdvancedNextBotControl",function()
	local bot = GetControlledBot()
	if !bot then return end
	
	local p = bot:WorldSpaceCenter():ToScreen()
	local w,h = 70,15
	
	if bot:ModifyPlayerControlHUD(p.x,p.y,w,h) then return end
	
	local hp = math.max(0,bot:Health())
	local maxhp = bot:GetMaxHealth()
	local hpfr = hp/maxhp
	
	surface.SetDrawColor(0,0,0)
	surface.DrawRect(p.x-w/2,p.y-h/2,w,h)
	
	surface.SetDrawColor(hpfr>0.5 and Color((1-(hpfr-0.5)*2)*255,255,0) or Color(255,hpfr*2*255,0))
	surface.DrawRect(p.x-w/2+1,p.y-h/2+1,(w-2)*hpfr,h-2)
	
	draw.SimpleText(math.floor(hp).."/"..maxhp,"BudgetLabel",p.x,p.y,nil,1,1)
	
	if bot:HasWeapon() then
		local wep = bot:GetActiveWeapon()
		
		draw.DrawText(wep:GetPrintName().."\nClip 1: "..bot:GetWeaponClip1().."/"..bot:GetWeaponMaxClip1().."\nClip 2: "..bot:GetWeaponClip2().."/"..bot:GetWeaponMaxClip2(),"BudgetLabel",p.x,p.y+h/2+10,nil,1)
	end
end)