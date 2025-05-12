---@class XUiDrawOptionalPredict : XLuaUi
local XUiDrawOptionalPredict = XLuaUiManager.Register(XLuaUi, "UiDrawOptionalPredict")

function XUiDrawOptionalPredict:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.OnClose)
    self:RegisterClickEvent(self.BtnCloseRole, self.OnClose)
end

function XUiDrawOptionalPredict:OnStart()
    self._DrawPredictConfigs = XDrawConfigs.GetDrawPredictConfigs()
    local latestEndTime = 0
    for _, v in pairs(self._DrawPredictConfigs) do
        if XFunctionManager.CheckInTimeByTimeId(v.TimeId) then
            local endTime = XFunctionManager.GetEndTimeByTimeId(v.TimeId)
            if endTime > latestEndTime then
                latestEndTime = endTime
            end
        end
    end
    self:SetAutoCloseInfo(latestEndTime, function(closeFlag)
        if closeFlag then
            XUiManager.TipText("DrawOptionalPredictExpired")
            self:OnClose()
        end
    end)
end

function XUiDrawOptionalPredict:OnEnable()
    ---@type XTableDrawPredict[]
    local datas = {}
    for _, v in pairs(self._DrawPredictConfigs) do
        if XFunctionManager.CheckInTimeByTimeId(v.TimeId) then
            table.insert(datas, v)
        end
    end
    XUiHelper.RefreshCustomizedList(self.Grid.parent, self.Grid, #datas, function(index, grid)
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, grid)
        local showDateTimeSplit = string.Split(datas[index].ShowUpTime, "-")
        local startShowDateTime = showDateTimeSplit[1]
        local endShowDateTime = showDateTimeSplit[2]
        local startShowDateTimeSplit = string.Split(startShowDateTime, " ")
        local endShowDateTimeSplit = string.Split(endShowDateTime, " ")
        uiObject.TxtTimeStart1.text = startShowDateTimeSplit[1]
        uiObject.TxtTimeStart2.text = startShowDateTimeSplit[2]
        uiObject.TxtTimeEnd1.text = endShowDateTimeSplit[1]
        uiObject.TxtTimeEnd2.text = endShowDateTimeSplit[2]

        XUiHelper.RefreshCustomizedList(uiObject.GridRole.parent, uiObject.GridRole, XTool.GetTableCount(datas[index].CharacterId), function(index2, grid2)
            local uiGridRoleObject = {}
            XUiHelper.InitUiClass(uiGridRoleObject, grid2)
            local charId = datas[index].CharacterId[index2]
            if XTool.IsNumberValid(charId) then
                uiGridRoleObject.GameObject:SetActiveEx(true)
                uiGridRoleObject.RImgRole:SetRawImage(XMVCA.XCharacter:GetCharHalfBodyImage(charId))
                XUiHelper.RegisterClickEvent(uiGridRoleObject, uiGridRoleObject.BtnHelp, function()
                    XDataCenter.AutoWindowManager.StopAutoWindow()
                    XLuaUiManager.Open("UiCharacterDetail", charId)
                end)
                uiGridRoleObject.TxtName.text = XMVCA.XCharacter:GetCharacterTradeName(charId)
                -- 能量数据
                local detailConfig = XMVCA.XCharacter:GetCharDetailTemplate(charId)
                local elementList = detailConfig.ObtainElementList
                local elementInfoList = {}
                for i, eleId in ipairs(elementList) do
                    local eleValue = detailConfig.ObtainElementValueList[i]
                    table.insert(elementInfoList, { Id = eleId, Value = eleValue })
                end
                table.sort(elementInfoList, function(a, b)
                    return a.Value > b.Value
                end)

                local elementInfoListCount = XTool.GetTableCount(elementInfoList)
                for i = 1, 3 do
                    local imgCharElement = uiGridRoleObject["RImgCharElement" .. i]
                    if i <= elementInfoListCount then
                        imgCharElement.gameObject:SetActiveEx(true)
                        imgCharElement:SetRawImage(XMVCA.XCharacter:GetCharElement(elementInfoList[i].Id).Icon2)
                    else
                        imgCharElement.gameObject:SetActiveEx(false)
                    end
                end

                -- 重新设置角色立绘宽高和位置偏移
                local drawPredictPosCfg = XDrawConfigs.GetDrawPredictPosConfig(charId)
                if drawPredictPosCfg then
                    local isPosXValid = XTool.IsNumberValid(drawPredictPosCfg.PosX)
                    local isPosYValid = XTool.IsNumberValid(drawPredictPosCfg.PosY)
                    local isWidthValid = XTool.IsNumberValid(drawPredictPosCfg.Width)
                    local isHeightValid = XTool.IsNumberValid(drawPredictPosCfg.Height)
                    
                    if isPosXValid or isPosYValid then
                        if isPosXValid and isPosYValid then
                            uiGridRoleObject.RectTransformImgRole.anchoredPosition = Vector2(drawPredictPosCfg.PosX, drawPredictPosCfg.PosY)
                        elseif isPosXValid then
                            uiGridRoleObject.RectTransformImgRole.anchoredPosition = Vector2(drawPredictPosCfg.PosX, uiGridRoleObject.RectTransformImgRole.anchoredPosition.y)
                        else
                            uiGridRoleObject.RectTransformImgRole.anchoredPosition = Vector2(uiGridRoleObject.RectTransformImgRole.anchoredPosition.x, drawPredictPosCfg.PosY)
                        end
                    end
                    
                    if isWidthValid or isHeightValid then
                        if isWidthValid and isHeightValid then
                            uiGridRoleObject.RectTransformImgRole.sizeDelta = Vector2(drawPredictPosCfg.Width, drawPredictPosCfg.Height)
                        elseif isWidthValid then
                            uiGridRoleObject.RectTransformImgRole.sizeDelta = Vector2(drawPredictPosCfg.Width, uiGridRoleObject.RectTransformImgRole.sizeDelta.y)
                        else
                            uiGridRoleObject.RectTransformImgRole.sizeDelta = Vector2(uiGridRoleObject.RectTransformImgRole.sizeDelta.x, drawPredictPosCfg.Height)
                        end
                    end
                end
            else
                uiGridRoleObject.GameObject:SetActiveEx(false)
            end
        end)
    end)
end

function XUiDrawOptionalPredict:OnClose()
    self.ParentUi:UpdatePredictButton()
    self:Close()
end

return XUiDrawOptionalPredict