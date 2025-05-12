---@class XUiMaverick3Story : XLuaUi 孤胆枪手剧情图鉴
---@field _Control XMaverick3Control
local XUiMaverick3Story = XLuaUiManager.Register(XLuaUi, "UiMaverick3Story")

function XUiMaverick3Story:OnAwake()
    XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
    self:BindHelpBtn(self.BtnHelp, "Maverick3StoryHelp")
end

function XUiMaverick3Story:OnStart()
    ---@type table<number,XTableMaverick3Story[]>
    local storys = {}
    local chapterIds = {}
    local cfgs = self._Control:GetStoryConfigs()
    for _, v in pairs(cfgs) do
        if not storys[v.Chapter] then
            storys[v.Chapter] = {}
        end
        table.insert(storys[v.Chapter], v)
        if not table.indexof(chapterIds, v.Chapter) then
            table.insert(chapterIds, v.Chapter)
        end
    end

    for index, chapterId in pairs(chapterIds) do
        local datas = storys[chapterId]
        local go = index == 1 and self.PanelChapter or XUiHelper.Instantiate(self.PanelChapter, self.PanelChapter.parent)
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.TxtTitle.text = self._Control:GetChapterById(chapterId).Name

        table.sort(datas, function(a, b)
            return a.Id < b.Id
        end)

        XUiHelper.RefreshCustomizedList(uiObject.GridStory.parent, uiObject.GridStory, #datas, function(i, prefab)
            local gridObject = {}
            local data = datas[i]
            local isCond, condDesc = true, ""
            if XTool.IsNumberValid(data.Condition) then
                isCond, condDesc = XConditionManager.CheckCondition(data.Condition)
            end
            XUiHelper.InitUiClass(gridObject, prefab)
            gridObject.TxtTitle.text = data.Name
            gridObject.RImgStory:SetRawImage(data.Bg)
            gridObject.PanelLock.gameObject:SetActiveEx(not isCond)
            gridObject.GridStory.CallBack = function()
                if not isCond then
                    XUiManager.TipError(condDesc)
                    return
                end
                XLuaUiManager.Open("UiMaverick3PoupuStoryDetail", data.Id)
            end
        end)
    end

    local endTime = self._Control:GetActivityGameEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end, nil, 0)
end

return XUiMaverick3Story