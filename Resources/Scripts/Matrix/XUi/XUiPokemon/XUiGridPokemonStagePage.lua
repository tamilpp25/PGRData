local XUiGridPokemonStagePage = XClass(nil, "XUiGridPokemonStagePage")
local XUiGridPokemonStage = require("XUi/XUiPokemon/XUiGridPokemonStage")
local CSVector2 = CS.UnityEngine.Vector2
local CSVector3 = CS.UnityEngine.Vector3
local CSQuaternion = CS.UnityEngine.Quaternion


function XUiGridPokemonStagePage:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.CurrIndex = 1
    self.PageStageCount = XDataCenter.PokemonManager.GetChapterPerPageStageCount()
    self.Stages = {}
    self.ConnectTransformDic = {}
    XTool.InitUiObject(self)
end

function XUiGridPokemonStagePage:InitStage(callback)
    for i = 1, XPokemonConfigs.PerPageCount do
        self.Stages[i] = XUiGridPokemonStage.New(self["Stage" .. i], self:CalculateStageIndex(i), callback)
    end
end

function XUiGridPokemonStagePage:Refresh(index)
    self.CurrIndex = index
    self:RefreshBg()
    self:RefreshStage()
    self:RefreshEffect()
end

function XUiGridPokemonStagePage:RefreshStage()
    for _, transform in pairs(self.ConnectTransformDic) do
        transform.gameObject:SetActiveEx(false)
    end
    for i = 1,self.PageStageCount do
        self["Stage" .. i].gameObject:SetActiveEx(false)
        self["Line" .. i].gameObject:SetActiveEx(false)
    end
    for i = 1, self.PageStageCount do
        local stageTemplate = self:GetUiTemplate(i, XPokemonConfigs.ObjType.Stage, self.CurrIndex + 1)
        local lineTemplate = self:GetUiTemplate(i, XPokemonConfigs.ObjType.Line, self.CurrIndex + 1)
        local stageIndex = self:CalculateStageIndex(i)
        local totalCount = XDataCenter.PokemonManager.GetStageCountByChapter()
        local passCount = XDataCenter.PokemonManager.GetPassedCountByChapterId(XDataCenter.PokemonManager.GetSelectChapter())
        local isShow = (stageIndex - passCount) <= 1
        if stageIndex > totalCount then break end
        self["Stage" .. i].gameObject:SetActiveEx(isShow)
        self["Line" .. i].gameObject:SetActiveEx(isShow)
        self.Stages[i]:Refresh(stageIndex)
        self:SetObjByTemplate(self["Stage" .. i], stageTemplate)
        self:SetObjByTemplate(self["Line" .. i].transform, lineTemplate)
        if (XDataCenter.PokemonManager.CheckStageIsPassed(XDataCenter.PokemonManager.GetStageFightStageId(stageIndex))
                or XDataCenter.PokemonManager.CheckIsSkip(XDataCenter.PokemonManager.GetStageFightStageId(stageIndex)))
                and stageIndex ~= totalCount then
            local startPos = CSVector2(lineTemplate.PosX, lineTemplate.PosY)
            local endPos, nextLineTemplate
            if i == self.PageStageCount then
                nextLineTemplate = self:GetUiTemplate(1, XPokemonConfigs.ObjType.Line, self.CurrIndex + 2)
            else
                nextLineTemplate = self:GetUiTemplate(i + 1, XPokemonConfigs.ObjType.Line, self.CurrIndex + 1)
            end
            endPos = CSVector2(nextLineTemplate.PosX, nextLineTemplate.PosY)
            self:CalculateConnectLine(startPos, endPos, i)
        end
    end
end

function XUiGridPokemonStagePage:GetUiTemplate(index,type,pages)
    local pageCount = XDataCenter.PokemonManager.GetStageCountByChapter() / self.PageStageCount
    if pages == 1 then
        return XDataCenter.PokemonManager.GetUiTemplate(index, type)
    elseif pages== pageCount then
        return XDataCenter.PokemonManager.GetUiTemplate((pageCount - 1) * self.PageStageCount + index, type)
    else
        local i = ((pages % 2) + 1) * self.PageStageCount + index
        return XDataCenter.PokemonManager.GetUiTemplate(i, type)
    end
end

function XUiGridPokemonStagePage:CalculateConnectLine(startPosition,endPosition,index)
    local transform = self.ConnectTransformDic[index]
    if not transform then
        transform = CS.UnityEngine.GameObject.Instantiate(self.Connect, self.PanelConnect)
        self.ConnectTransformDic[index] = transform
    end

    if index == self.PageStageCount then
        endPosition.y = endPosition.y + self.Transform.parent.rect.height
    end
    local vecOffset = endPosition - startPosition
    local width = vecOffset.magnitude
    local position = (startPosition + endPosition) / 2
    local sizeDelta = transform.sizeDelta
    transform.sizeDelta = CSVector2(width, sizeDelta.y)
    transform.anchoredPosition = CSVector2(position.x, position.y)
    transform.localRotation = CSQuaternion.Euler(CSVector2.Angle(CSVector2(1, 0), vecOffset) * CSVector3(0, 0, 1))
    transform.gameObject:SetActiveEx(true)
end

function XUiGridPokemonStagePage:SetObjByTemplate(transform,config)
    local position = CSVector2(config.PosX, config.PosY)
    local scale = CSVector3(config.ScaleX, config.ScaleY, config.ScaleZ)
    transform.anchoredPosition = position
    transform.localScale = scale
end

function XUiGridPokemonStagePage:RefreshEffect()
    for i = 1, 4 do
        self["Effect" .. i].gameObject:SetActiveEx(false)
    end
    if  self.CurrIndex % 2 == 0 then
        self.Effect1.gameObject:SetActiveEx(true)
    elseif self.CurrIndex % 2 == 1 then
        self.Effect2.gameObject:SetActiveEx(true)
    end
end

function XUiGridPokemonStagePage:RefreshBg()
    local index = self.CurrIndex * self.PageStageCount + 1
    local totalCount = XDataCenter.PokemonManager.GetStageCountByChapter()
    index = XMath.Clamp(index, 1, totalCount)

    local bgPath = XDataCenter.PokemonManager.GetStageBg(index)
    self.BgCommonBai:SetRawImage(bgPath)
end


function XUiGridPokemonStagePage:CalculateStageIndex(index)
    return self.CurrIndex * self.PageStageCount + index or 0
end

return XUiGridPokemonStagePage