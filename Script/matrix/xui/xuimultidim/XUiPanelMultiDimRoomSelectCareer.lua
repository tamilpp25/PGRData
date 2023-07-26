local XUiPanelMultiDimRoomSelectCareer = XClass(nil,"XUiPanelMultiDimRoomSelectCareer")

---@param transform UnityEngine.RectTransform
function XUiPanelMultiDimRoomSelectCareer:Ctor(transform,index,defaultCareer,stageId)
    self.Transform = transform
    self.GameObject = transform.gameObject
    self.SelectCareer = defaultCareer
    self.Index = index
    self.CareerBtn = {}
    local difficultyCfg = XMultiDimConfig.GetMultiDimDifficultyStageData(stageId)
    self.DifficultyId = difficultyCfg.Id
    XTool.InitUiObject(self)
    self:InitView()
end

function XUiPanelMultiDimRoomSelectCareer:InitView()
    local careers = XMultiDimConfig.GetMultiDimCareerInfo()
    for _, cfg in pairs(careers) do
        local obj = CS.UnityEngine.GameObject.Instantiate(self.BtnType,self.PanelTypeList)
        local btn = obj:GetComponent("XUiButton")
        btn:SetRawImage(cfg.Icon)
        self.CareerBtn[cfg.Career] = {
            Btn = btn,
            CareerId = cfg.Career
        }
        btn.CallBack = function() 
            self:OnClickBtnCareer(cfg.Career)
        end
        if cfg.Career == self.SelectCareer then
            btn:SetButtonState(CS.UiButtonState.Select)
        else
            btn:SetButtonState(CS.UiButtonState.Normal)
        end
    end
    self.BtnType.gameObject:SetActiveEx(false)
end

function XUiPanelMultiDimRoomSelectCareer:OnClickBtnCareer(careerId)
    XDataCenter.MultiDimManager.SelectTeammatesCareer(self.DifficultyId, self.Index, careerId, function()
        for id, btnInfo in pairs(self.CareerBtn) do
            if id == careerId then
                btnInfo.Btn:SetButtonState(CS.UiButtonState.Select)
            else
                btnInfo.Btn:SetButtonState(CS.UiButtonState.Normal)
            end
        end
    end)
end


return XUiPanelMultiDimRoomSelectCareer