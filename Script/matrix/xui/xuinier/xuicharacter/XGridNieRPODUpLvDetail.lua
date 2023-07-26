local XGridNieRPODUpLvDetail = XClass(nil, "XGridNieRPODUpLvDetail")
local TIME_TWEEN = 1.5
function XGridNieRPODUpLvDetail:Ctor(rootUi, ui)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    
end

function XGridNieRPODUpLvDetail:UpdateInfo(data)
    local nieRPOD = XDataCenter.NieRManager.GetNieRPODData()

    local nameStr = nieRPOD:GetNieRPODName()

    self.TxtName.text = nameStr
    self.RawImage:SetRawImage(nieRPOD:GetNieRPODHeadBigIcon())
    self.TxtLevel.text = data.OldLevel

    local itemId = data.Item.TemplateId
    local itemCount = data.Item.Count

    self.RImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemBigIcon(itemId))
    XUiHelper.SetQualityIcon(self.RootUi, self.ImgQuality, XDataCenter.ItemManager.GetItemQuality(itemId))

    self.TxtUpLvCavansGroup.alpha = 0

    if data.IsOldMaxLevel then
        self.TxtExpNow.text = ""
        self.TxtExpALL.text = "Max"
        self.ImgExpBar.fillAmount = 1
        self.TxtCount.text = "+" .. itemCount
    else
        local newLevel = nieRPOD:GetNieRPODLevel()
        local newExp = nieRPOD:GetNieRPODExp()
        local oldMaxExp = data.OldMaxExp
        local newMaxExp = nieRPOD:GetNieRPODMaxExp()
        local changeExp
        local changeCount
        if data.OldLevel < newLevel then
            changeExp = oldMaxExp - data.OldExp
        else
            changeExp = newExp - data.OldExp
        end
        self.TxtExpALL.text = "/" .. oldMaxExp
        XUiHelper.Tween(TIME_TWEEN, function(f)
            if XTool.UObjIsNil(self.Transform) then
                return
            end
            local tmpChangeExp = math.floor(f * changeExp)
            local tmpPercent = (data.OldExp + tmpChangeExp) / oldMaxExp

            self.TxtExpNow.text = tmpChangeExp
            self.ImgExpBar.fillAmount = tmpPercent
            self.TxtCount.text = "+" .. tmpChangeExp
        end, function()
            if XTool.UObjIsNil(self.Transform) then
                return
            end
            local isMaxLevel = nieRPOD:CheckNieRPODMaxLevel()
            if data.OldLevel < newLevel then
                self.LevelUpEnable.gameObject:PlayTimelineAnimation(function()
                    self.LevelUpDisable.gameObject:PlayTimelineAnimation(function()
                    end)
                end)
            end
            if isMaxLevel then
                self.TxtLevel.text = newLevel
                self.TxtExpNow.text = ""
                self.TxtExpALL.text = "Max"
                self.ImgExpBar.fillAmount = 1
                self.TxtCount.text = "+" .. itemCount
            else
                self.TxtLevel.text = newLevel
                self.TxtExpNow.text = newExp
                self.TxtExpALL.text = "/" .. newMaxExp
                self.ImgExpBar.fillAmount = newExp / newMaxExp
                self.TxtCount.text = "+" .. itemCount
            end
        end)
    end
end

return XGridNieRPODUpLvDetail