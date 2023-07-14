local XUiAssignOccupyProgress = XLuaUiManager.Register(XLuaUi, "UiAssignOccupyProgress")
local XUiGridAssignOccupyProgress = require("XUi/XUiAssign/XUiGridAssignOccupyProgress")

function XUiAssignOccupyProgress:OnAwake()
    self:InitButton()
    self.GridCharacterDic = {}
    XEventManager.AddEventListener(XEventId.EVENT_ASSIGN_SELECT_OCCUPY_END, self.Refresh, self)
end

function XUiAssignOccupyProgress:InitButton()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnClose, self.Close)
end

function XUiAssignOccupyProgress:OnEnable()

    self:Refresh()
end

function XUiAssignOccupyProgress:OnDisable()

end

function XUiAssignOccupyProgress:Refresh()
    
    local chapterIdList = XDataCenter.FubenAssignManager.GetChapterIdList()
    local total = #chapterIdList
    local curr = 0

    for i, chapterId in ipairs(chapterIdList) do
        local grid = self.GridCharacterDic[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridCharacter, self.GridCharacter.parent)
            grid = XUiGridAssignOccupyProgress.New(ui, self)
            self.GridCharacterDic[i] = grid
        end
        grid:Refresh(chapterId)

        local chapterData = XDataCenter.FubenAssignManager.GetChapterDataById(chapterId)
        if chapterData:IsOccupy() then
            curr = curr + 1
        end
    end
    self.GridCharacter.gameObject:SetActiveEx(false)

    self.TxtProgress.text = CS.XTextManager.GetText("AssignChapterProgress", curr, total)
end

function XUiAssignOccupyProgress:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_ASSIGN_SELECT_OCCUPY_END, self.Refresh, self)	
end