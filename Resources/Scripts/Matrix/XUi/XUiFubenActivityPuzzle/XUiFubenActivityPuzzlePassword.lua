local tableInsert = table.insert
local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiFubenActivityPuzzlePassword = XLuaUiManager.Register(XLuaUi, "UiFubenActivityPuzzlePassword")

local XUiPuzzleDercyptionPasswordItem = require("XUi/XUiFubenActivityPuzzle/XUiPuzzleDercyptionPasswordItem")

function XUiFubenActivityPuzzlePassword:OnAwake()
    
end

function XUiFubenActivityPuzzlePassword:OnStart(rootUi)
    self.RootUi = rootUi
    self.PasswordItemPool = {}
    self.PasswordItemList = {}
    self:AutoRegisterBtn()
end

function XUiFubenActivityPuzzlePassword:OnEnable()
    self:InitPasswordList(self.RootUi.PuzzleId)
    self:Refreash(self.RootUi.PuzzleId)
end

function XUiFubenActivityPuzzlePassword:OnDisable()
    
end

function XUiFubenActivityPuzzlePassword:OnDestroy()
    
end

function XUiFubenActivityPuzzlePassword:OnGetEvents()
    return {
        XEventId.EVENT_DRAG_PUZZLE_GAME_CHANGE_PASSWORD,
        XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_CHECK_WORD_ERROR,
        XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_COMPLETE,
    }
end

function XUiFubenActivityPuzzlePassword:OnNotify(evt, ...)
    if evt == XEventId.EVENT_DRAG_PUZZLE_GAME_CHANGE_PASSWORD then
        self:ChangePassword(...)
    elseif evt == XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_CHECK_WORD_ERROR then
        --XUiManager.TipText("DragPuzzleActivityDercyptionErrorPassword")
        XDataCenter.FubenActivityPuzzleManager.HitPasswordMessage(...)
        self:Close()
    elseif evt == XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_COMPLETE then
        self:Close()
    end
end

function XUiFubenActivityPuzzlePassword:Refreash(puzzleId)
    if not self.PasswordList or not next(self.PasswordList) then
        return
    end

    self.TxtTips.text = CsXTextManagerGetText("DragPuzzleActivityDercyptionTips", XFubenActivityPuzzleConfigs.GetPuzzlePasswordHintById(puzzleId))

    local passwordIdxArr = {}
    for index, password in ipairs(self.PasswordList) do
        tableInsert(passwordIdxArr, {Index = index, Password = password})
    end

    local onCreate = function(item, data)
        item:SetActiveEx(true)
        item:OnCreate(data)
        self.PasswordItemList[data.Index] = item
    end

    XUiHelper.CreateTemplates(self, self.PasswordItemPool, passwordIdxArr, XUiPuzzleDercyptionPasswordItem.New, self.PasswordItem.gameObject, self.PanelDigital, onCreate)
end

function XUiFubenActivityPuzzlePassword:AutoRegisterBtn()
    self.BtnBack.CallBack = function () self:Close() end
    self.BtnEnter.CallBack = function () self:OnBtnEnterClick() end
end

function XUiFubenActivityPuzzlePassword:InitPasswordList(puzzleId)
    local CenterPasswordList = XDataCenter.FubenActivityPuzzleManager.GetPasswordByPuzzleId(puzzleId)
    self.PasswordList = {}
    for _, centerPassword in ipairs(CenterPasswordList) do
        tableInsert(self.PasswordList, centerPassword)
    end
end

function XUiFubenActivityPuzzlePassword:OnBtnEnterClick()
    XDataCenter.FubenActivityPuzzleManager.ExchangePassword(self.RootUi.PuzzleId, self.PasswordList)
end

function XUiFubenActivityPuzzlePassword:ChangePassword(index, flag)
    if self.PasswordList[index] then
        if flag == "Up" then
            self.PasswordList[index] = self.PasswordList[index] + 1
            if self.PasswordList[index] > 9 then self.PasswordList[index] = 0 end
        else
            self.PasswordList[index] = self.PasswordList[index] - 1
            if self.PasswordList[index] < 0 then self.PasswordList[index] = 9 end
        end
    end

    self.PasswordItemList[index]:SetTextPassword(self.PasswordList[index])
end