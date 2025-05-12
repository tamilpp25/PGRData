--- 背景预制体控件
---@class XUiPanelBgNormal: XUiNode
local XUiPanelBgNormal = XClass(XUiNode, 'XUiPanelBgNormal')

local BgType = {
    Default = 1,
    FullBg = 2,
}

function XUiPanelBgNormal:OnStart(characterId, typeCfg, customParams)
    self.CharacterId = characterId
    self.TypeCfg = typeCfg
    self.CustomParams = customParams
    
    self:RefreshShow()
end

function XUiPanelBgNormal:RefreshShow()
    --- 目前类型比较少，且比较简单，直接在这里判断处理
    if BgType.Default == self.TypeCfg.Type then
        if self.RImgTeamIcon then
            --队伍图标
            local teamIcon=self._Control:GetCharacterTeamIconById(self.CharacterId)
            if not string.IsNilOrEmpty(teamIcon) then
                self.RImgTeamIcon:SetRawImage(teamIcon)
            else
                --读默认的透明图片
                self.RImgTeamIcon:SetRawImage(CS.XGame.ClientConfig:GetString("TrustNoData"))
            end
        end
    elseif BgType.FullBg == self.TypeCfg.Type then
        if self.RImgFullBg and not string.IsNilOrEmpty(self.CustomParams[1]) then
            self.RImgFullBg:SetRawImage(self.CustomParams[1])
        end
    end
end

return XUiPanelBgNormal