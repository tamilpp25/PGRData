---@class XUiPlanetUtil
local XUiPlanetUtil = {}

function XUiPlanetUtil.SetHp(imgHp, hp)
    imgHp.fillAmount = hp
    local color
    if hp <= 0.2 then
        color = XUiHelper.Hexcolor2Color("BB4242FF")
    elseif 0.2 < hp and hp <= 0.5 then
        color = XUiHelper.Hexcolor2Color("FFDC3BFF")
    elseif hp > 0.5 then
        color = XUiHelper.Hexcolor2Color("47CA4FFF")
    end
    if color then
        imgHp.color = color
    end
end

return XUiPlanetUtil
