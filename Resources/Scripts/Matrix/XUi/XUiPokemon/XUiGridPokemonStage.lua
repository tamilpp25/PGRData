local XUiGridPokemonStage = XClass(nil, "XUiGridPokemonStage")

function XUiGridPokemonStage:Ctor(ui, stageId, callback)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.StageId = stageId
    self.Callback = callback
    XTool.InitUiObject(self)
    self.Btn.CallBack = function()
        self.Callback(self.StageId)
    end
end



function XUiGridPokemonStage:Refresh(stageId)
    self.StageId = stageId
    self.TxtName.text = XDataCenter.PokemonManager.GetStageName(stageId)
    self.ImgStage:SetRawImage(XDataCenter.PokemonManager.GetStageIcon(stageId))
    if self.ImgBoss then
        if XDataCenter.PokemonManager.IsBossStage(stageId) then
            self.ImgBoss.gameObject:SetActiveEx(true)
            self.ImgBoss:SetRawImage(XDataCenter.PokemonManager.GetStageBossHeadIcon(stageId))
        else
            self.ImgBoss.gameObject:SetActiveEx(false)
        end
    end
    if self.CommonFuBenClear then
        if XDataCenter.PokemonManager.CheckStageIsPassed(XDataCenter.PokemonManager.GetStageFightStageId(stageId)) and self.CommonFuBenClear then
            self.CommonFuBenClear.gameObject:SetActiveEx(true)
        else
            self.CommonFuBenClear.gameObject:SetActiveEx(false)
        end
    end

    if self.PokemonPass then
        local isSkip = XDataCenter.PokemonManager.CheckIsSkip(XDataCenter.PokemonManager.GetStageFightStageId(self.StageId))
        self.PokemonPass.gameObject:SetActiveEx(isSkip)
    end
end

return XUiGridPokemonStage