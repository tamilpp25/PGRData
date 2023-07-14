local Base = require("XUi/XUiSuperTower/Common/XUiSTChildPanel")
--=====================
--爬塔掉落页面详细信息面板
--=====================
local XUiStCpRolePanel = XClass(Base, "XUiStCpRolePanel")

function XUiStCpRolePanel:InitPanel()
    self:InitRole()
end

function XUiStCpRolePanel:InitRole()
    for i = 1, 3 do
        local headIcon = self["RImgRole" .. i]
        if headIcon then
            local roleId = self.RootUi.Team:GetEntityIdByTeamPos(i)
            if roleId and roleId > 0 then
                local role = XDataCenter.SuperTowerManager.GetRoleManager():GetRole(roleId)
                headIcon:SetRawImage(role:GetCharacterViewModel():GetBigHeadIcon())
                headIcon.gameObject:SetActiveEx(true)
            else
                headIcon.gameObject:SetActiveEx(false)
            end
        end
    end
end
 
return XUiStCpRolePanel