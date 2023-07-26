local XUiFightMap = XLuaUiManager.Register(XLuaUi, "UiFightMap")

function XUiFightMap:OnAwake()
    self.BtnTanchuangCloseBig.CallBack = function()
        local fight = CS.XFight.Instance
        if fight then
            fight.InputControl:OnClick(CS.XNpcOperationClickKey.CommonUiClose, CS.XOperationClickType.KeyDown)
            fight.InputControl:OnClick(CS.XNpcOperationClickKey.CommonUiClose, CS.XOperationClickType.KeyUp)
        end
        self:Close()
    end
end

function XUiFightMap:HideAll()
    self.RImgFightMapScene03403.gameObject:SetActiveEx(false)
    self.RImgFightMapScene03404.gameObject:SetActiveEx(false)
    self.RImgFightMapScene03801A.gameObject:SetActiveEx(false)
    self.RImgFightMapScene03801B.gameObject:SetActiveEx(false)
end

function XUiFightMap:OnEnable(name)
    self:HideAll()
    if self[name] then
        self[name].gameObject:SetActiveEx(true)
    end
end