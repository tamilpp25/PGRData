---@class XUiDlcCasualGamesUtility
local XUiDlcCasualGamesUtility = XClass(nil, "XUiDlcCasualGamesUtility")
local IPairs = ipairs

---@param textNameList UnityEngine.UI.Text[]
---@param imgHeadList UnityEngine.UI.Image[]
---@param btnPlayerList XUiComponent.XUiButton[]
---@param data XDlcCasualRank
function XUiDlcCasualGamesUtility.RefreshRankTeamGrid(textNameList, imgHeadList, btnPlayerList, data)
    if not data then
        return
    end
    
    local playerRankList = data:GetPlayerList()
    for i, dataPlayer in IPairs(playerRankList) do
        local txtName = textNameList[i]
        local headIcon = imgHeadList[i]
        local playerButton = btnPlayerList[i]
        
        if dataPlayer then
            txtName.text = dataPlayer:GetPlayerName()

            XUiPlayerHead.InitPortrait(dataPlayer:GetHeadPortraitId(), dataPlayer:GetHeadFrameId(), headIcon)
            XUiHelper.RegisterClickEvent(nil, playerButton, function()
                XDataCenter.PersonalInfoManager.ReqShowInfoPanel(dataPlayer:GetPlayerId())
            end, true)
        end

        playerButton.gameObject:SetActiveEx(dataPlayer ~= nil)
    end

    for i = #playerRankList + 1, #btnPlayerList do
        btnPlayerList[i].gameObject:SetActiveEx(false)
    end
end

---@param prefixStr string
---@param uiClass table
---@param count number
function XUiDlcCasualGamesUtility.GetComponentList(prefixStr, uiClass, count)
    local componentList = {}

    for i = 1, count do
        componentList[i] = uiClass[prefixStr .. i]
    end
    
    return componentList
end

---@param roomCasePrefix string
---@param charPanel UnityEngine.Transform
---@param uiClass table
---@param count number
---@param callback function
function XUiDlcCasualGamesUtility.InitRoomCharCase(roomCasePrefix, charPanel, callback, uiClass, count, isRevert)
    charPanel.gameObject:SetActiveEx(false)
    
    for i = 1, count do
        ---@type UnityEngine.GameObject
        local grid = nil
        local roomCase = uiClass[roomCasePrefix .. i]

        if not roomCase then
            return
        end
        if i == 1 then
            charPanel:SetParent(roomCase)
            charPanel.gameObject:SetActiveEx(true)
            grid = charPanel
        else
            grid = XUiHelper.Instantiate(charPanel.gameObject, roomCase)
        end
        if isRevert then
            grid.transform:Reset()
        end
        if callback then
            callback(i, grid)
        end
    end
end

function XUiDlcCasualGamesUtility.RandomPlayAnimation(panelRoleModel)
    local animator = panelRoleModel:GetAnimator()
    local clips = animator.parameters
    local index = XTool.Random(0, clips.Length - 1)

    panelRoleModel:CrossFadeAnim(clips[index].name)
end

---@param animator UnityEngine.Animator
function XUiDlcCasualGamesUtility.LoopPlayAnimation(animator, animationName, layer)
    if XTool.UObjIsNil(animator) or string.IsNilOrEmpty(animationName) then
        return
    end

    local animatorInfo = animator:GetCurrentAnimatorStateInfo(layer or 0)

    if (animatorInfo:IsName(animationName) and animatorInfo.normalizedTime >= 1) 
        or not animatorInfo:IsName(animationName) then
        animator:Play(animationName)
    end
end

---@param players XDlcCasualPlayerResult[]
function XUiDlcCasualGamesUtility.GetResultHasMvpAndPlayerList(players)
    if not players then
        return {}
    end
    
    local isMvpSameScore = false
    local playerOnlineList = {}
    local playerOfflineList  = {}

    for i = 1, #players do
        if not players[i]:IsOffline() then
            playerOnlineList[#playerOnlineList + 1] = players[i]
        else
            playerOfflineList[#playerOfflineList + 1] = players[i]
        end
    end
    table.sort(playerOnlineList, function(playerA, playerB)
        return playerA:GetPersonalScore() > playerB:GetPersonalScore()
    end)
    table.sort(playerOfflineList, function(playerA, playerB)
        return playerA:GetPersonalScore() > playerB:GetPersonalScore()
    end)
    if playerOnlineList[2] and playerOnlineList[1] then
        isMvpSameScore = playerOnlineList[2]:GetPersonalScore() == playerOnlineList[1]:GetPersonalScore()
    end

    return isMvpSameScore, XTool.MergeArray(playerOnlineList, playerOfflineList)
end

---@param players XDlcCasualPlayerResult[]
function XUiDlcCasualGamesUtility.GetDataResultPlayerList(players)
    if not players then
        return {}
    end
    
    local playerOnlineList = {}
    local playerOfflineList  = {}
    local selfIndex = 1

    for i = 1, #players do
        if not players[i]:IsOffline() then
            if players[i]:GetPlayerId() == XPlayer.Id then
                selfIndex = #playerOnlineList + 1
            end
            playerOnlineList[#playerOnlineList + 1] = players[i]
        else
            playerOfflineList[#playerOfflineList + 1] = players[i]
        end
    end

    if selfIndex ~= 1 then
        local temp = playerOnlineList[1]

        if temp and playerOnlineList[selfIndex] then
            playerOnlineList[1] = playerOnlineList[selfIndex]
            playerOnlineList[selfIndex] = temp
        end
    end

    return XTool.MergeArray(playerOnlineList, playerOfflineList)
end

return XUiDlcCasualGamesUtility