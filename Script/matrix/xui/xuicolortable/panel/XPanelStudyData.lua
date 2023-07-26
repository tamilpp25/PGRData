-- 研究数据详情
local XPanelStudyData = XClass(nil, "XPanelStudyData")

-- 数字跳动时长
local ChangeValueAnimDuration = 0.5
local Karelina = 4

function XPanelStudyData:Ctor(root, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Root = root

    self:_InitUiObject()
end

function XPanelStudyData:RefreshColorData(studyDatas)
    local captainId = XDataCenter.ColorTableManager.GetGameManager():GetGameData():GetCaptainId()
    local mapId = XDataCenter.ColorTableManager.GetGameManager():GetGameData():GetMapId()
    local studyDataLimit = XColorTableConfigs.GetMapStudyDataLimit(mapId)
    for colorType, value in ipairs(studyDatas) do
        self:ShowDataEffect(colorType, value)
        if captainId == Karelina then
            self["TxtSpecialTool" .. colorType].text = value
        else
            if XUiHelper.GetText("ColorTableStudyDataTxt", value, studyDataLimit) ~= "ColorTableStudyDataTxt" then
                self["TxtSpecialTool" .. colorType].text = XUiHelper.GetText("ColorTableStudyDataTxt", value, studyDataLimit)
            else
                self["TxtSpecialTool" .. colorType].text = value .. " / " .. studyDataLimit
            end
            
        end
    end
    self.StudyDatas = studyDatas
end

function XPanelStudyData:RefreshOneColorData(colorType, value)
    local textName = "TxtSpecialTool" .. colorType
    local beforeValue = self.StudyDatas[colorType]

    self:ShowDataEffect(colorType, value)
    if self.DataChangeAnim[colorType] then
        XScheduleManager.UnSchedule(self.DataChangeAnim[colorType])
    end
    self[textName].text = beforeValue
    self.StudyDatas[colorType] = value
    self:_PlayValueAnim(colorType, beforeValue, value)
end

function XPanelStudyData:ShowDataEffect(colorType, afterValue)
    if self.StudyDatas[colorType] ~= afterValue and self["PanelEffect" .. colorType] then
        self["PanelEffect" .. colorType].gameObject:SetActiveEx(false)
        self["PanelEffect" .. colorType].gameObject:SetActiveEx(true)
    end
end

function XPanelStudyData:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_STUDYDATACHANGE, self.RefreshColorData, self)
end

function XPanelStudyData:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_STUDYDATACHANGE, self.RefreshColorData, self)
end

-- private
-------------------------------------------------------------------

function XPanelStudyData:_InitUiObject()
    local gamedata = XDataCenter.ColorTableManager.GetGameManager():GetGameData()
    XTool.InitUiObject(self)
    for _, colorType in pairs(XColorTableConfigs.ColorType) do
        self["RImgSpecialTool" .. colorType]:SetRawImage(XColorTableConfigs.GetStudyDataIcon(colorType))
        if gamedata:CheckIsFirstGuideStage() then
            self["PanelSpecialTool" .. colorType].gameObject:SetActiveEx(XDataCenter.ColorTableManager.GetGameManager():CheckIsHideInGuildStage(colorType))
        end
        if self["PanelEffect" .. colorType] then
            self["PanelEffect" .. colorType].gameObject:SetActiveEx(false)
        end
    end
    -- 数字跳动字典
    self.DataChangeAnim = {}
    self.StudyDatas = {}
end

-- 播放数字跳动动画
function XPanelStudyData:_PlayValueAnim(colorType, beforeValue, afterValue)
    local textName = "TxtSpecialTool" .. colorType
    local changeValue = afterValue - beforeValue

    self.DataChangeAnim[colorType] = XUiHelper.Tween(ChangeValueAnimDuration, function(f)
        if XTool.UObjIsNil(self[textName]) then  -- 防止动画还没结束就关闭界面导致计时器报错
            return
        end
        self[textName].text = math.floor(beforeValue + changeValue * f)
    end, function()
        if XTool.UObjIsNil(self[textName]) then
            return
        end
        self[textName].text = afterValue
    end)
end

-------------------------------------------------------------------

return XPanelStudyData