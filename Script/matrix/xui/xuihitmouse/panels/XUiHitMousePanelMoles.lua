
local XUiHitMousePanelMoles = {}

function XUiHitMousePanelMoles.Init(ui)
    ui.MolesPanel = {}
    XTool.InitUiObjectByUi(ui.MolesPanel, ui.PanelMoles)
    XUiHitMousePanelMoles.InitMoles(ui)
end

function XUiHitMousePanelMoles.InitMoles(ui)
    if not ui or not ui.MolesPanel then return end
    local XMole = require("XUi/XUiHitMouse/Mole/XUiMole")
    ui.Moles = {}
    local index = 1
    while(true) do
        local molePrefab = ui.MolesPanel["MoleHole" .. index]
        if not molePrefab then
            break
        end
        ui.Moles[index] = XMole.New(molePrefab, index,
            function()
                ui.MolesPanel.SoundHitMonster.gameObject:SetActiveEx(false)
                ui.MolesPanel.SoundHitMonster.gameObject:SetActiveEx(true)
            end)
        index = index + 1
    end
end

local function GetMoleNum(ui)
    local stageId = ui.StageId
    local refreshIntervalDic = ui.RefreshIntervalDic
    local stageCfg = XHitMouseConfigs.GetCfgByIdKey(
        XHitMouseConfigs.TableKey.Stage,
        stageId
    )
    if not stageCfg then
        return {}
    end
    local targetRefreshCfg
    if ui.IsFever then
        local refreshId = stageCfg.FeverRefresh
        targetRefreshCfg = XHitMouseConfigs.GetCfgByIdKey(
            XHitMouseConfigs.TableKey.Refresh,
            refreshId
        )
    else
        local targetHitKey = 1
        for _, hitKey in pairs(ui.RefreshHitKeyList) do
            if ui.ComboCount >= hitKey then
                targetHitKey = hitKey
                break
            end
        end
        targetRefreshCfg = ui.HitKey2RefreshDic[targetHitKey]
    end
    math.randomseed(XTime.GetServerNowTimestamp())
    local baseType1Num = math.random(targetRefreshCfg.Type1NumberMin, targetRefreshCfg.Type1NumberMax)
    local baseType2Num = math.random(targetRefreshCfg.Type2NumberMin, targetRefreshCfg.Type2NumberMax)
    local resultDic = {}
    local sureMoleDic = {} --保底要出现的地鼠
    for index, turn in pairs(refreshIntervalDic) do
        if stageCfg.RefreshMaxIntervals[index] > 0
            and turn >= stageCfg.RefreshMaxIntervals[index] then
            sureMoleDic[index] = true
        end
    end
    local refreshMoleNum = 0
    for _,_ in pairs(stageCfg.RefreshMaxIntervals) do
        refreshMoleNum = refreshMoleNum + 1
    end
    local index = refreshMoleNum
    while(index > 0) do
        if baseType1Num > 0 and sureMoleDic[index] then
            resultDic[index] = 1
            baseType1Num = baseType1Num - 1
        end
        index = index - 1
    end

    local totalWeight = 0
    for _, weight in pairs(stageCfg.MouseWeights) do
        totalWeight = totalWeight + weight
    end
    --XLog.Debug("totalWeight:", totalWeight)
    for count = 1, baseType1Num do
        math.randomseed(XTime.GetServerNowTimestamp() + count)
        local randomWeight = math.random(1, totalWeight)
        local id = 1
        local tempAddWeight = 0
        for weightIndex, weight in pairs(stageCfg.MouseWeights) do
            tempAddWeight = tempAddWeight + weight
            if randomWeight <= tempAddWeight then
                id = weightIndex
                break
            end
        end
        if not resultDic[id] then
            resultDic[id] = 0
        end
        resultDic[id] = resultDic[id] + 1
    end

    for moleId = 1, refreshMoleNum do
        if not refreshIntervalDic[moleId] then
            refreshIntervalDic[moleId] = 0
        end
        if resultDic[moleId] and resultDic[moleId] > 0 then
            refreshIntervalDic[moleId] = 0
        else
            refreshIntervalDic[moleId] = refreshIntervalDic[moleId] + 1
        end
    end
    resultDic[4] = baseType2Num
    return resultDic
end

local function GetMoleDic(ui)
    local moleNumDic = GetMoleNum(ui)
    local moleNum = 0
    for _, num in pairs(moleNumDic) do
        moleNum = moleNum + num
    end
    local moleDic = {}
    local tempIndexDic = {}
    local maxNum = XDataCenter.HitMouseManager.GetMoleMaxNum()
    for i = 1, maxNum do
        moleDic[i] = 0
        tempIndexDic[i] = i
    end
    local pos = {}
    for i = 1, moleNum do
        math.randomseed(XTime.GetServerNowTimestamp() + i)
        local random = math.random(1, #tempIndexDic)
        pos[i] = tempIndexDic[random]
        table.remove(tempIndexDic, random)
    end
    local moleResult = {}
    local tempIndex = 1
    for moleId, num in pairs(moleNumDic) do
        if num > 0 then
            for i = 1, num do
                moleResult[pos[tempIndex]] = moleId
                tempIndex = tempIndex + 1
            end
        end
    end
    return moleResult
end

function XUiHitMousePanelMoles.SetMole(ui)
    local moleResultDic = GetMoleDic(ui)
    for index = 1, #ui.Moles do
        ui.Moles[index]:Init()
        if moleResultDic[index] then
            ui.Moles[index]:SetMole(moleResultDic[index])
        end
    end
end

function XUiHitMousePanelMoles.StartRound(ui)
    XUiHitMousePanelMoles.SetMole(ui)
    ui.MolesPanel.SoundStartRound.gameObject:SetActiveEx(false)
    ui.MolesPanel.SoundStartRound.gameObject:SetActiveEx(true)
    for index, mole in pairs(ui.Moles) do
        ui.Moles[index].RoundStartFlag = true
    end
end

function XUiHitMousePanelMoles.ClearRound(ui)
    for index, mole in pairs(ui.Moles) do
        ui.Moles[index].ClearRound = true
    end
end

function XUiHitMousePanelMoles.OnUpdate(ui)
    if ui.BreakTimeFlag then return end
    local moles = ui.Moles
    if not moles then return end
    local inRound = ui.RoundTime and ui.RoundTime > 0
    for _, mole in pairs(moles) do
        if inRound then
            mole:CheckShowTime(ui.RoundTime)
        end
        mole:UpdateStatus()
    end
    for _, mole in pairs(moles) do
        if mole.NotHit == true then
            mole.NotHit = false
            mole.isNeedHit = false
            ui.MolesPanel.SoundCloseGaiZi.gameObject:SetActiveEx(false)
            ui.MolesPanel.SoundCloseGaiZi.gameObject:SetActiveEx(true)
            ui:ComboFailed()
            if ui.IsFever then
                return
            end
        end
    end
    local checkFever = false
    for _, mole in pairs(moles) do
        if mole.IsDied == true and not mole.Dying then
            mole.Dying = true
            ui:OnMoleDead(mole)
            ui.MolesPanel.SoundCloseGaiZi.gameObject:SetActiveEx(false)
            ui.MolesPanel.SoundCloseGaiZi.gameObject:SetActiveEx(true)
            if ui.IsFever and not checkFever then
                if mole.isNeedHit then
                    checkFever = true
                end
            end
        end
    end
    if ui.IsFever and checkFever then
        for _, mole in pairs(moles) do
            if mole.isNeedHit and not mole.IsDied then
                mole.FeverHit = true
            end
        end
    end
    local isEndRound = XUiHitMousePanelMoles.CheckRoundEnd(moles)
    if isEndRound then
        ui:EndRound()
        return
    end
    if ui.ClearRoundFlag then return end
    local isClearMole = XUiHitMousePanelMoles.CheckMoleClear(moles)
    if isClearMole then
        ui:ClearRound(true)
        return
    end
end

--===================
--检查是否已经满足清理回合的条件
--===================
function XUiHitMousePanelMoles.CheckMoleClear(moles)
    for _, mole in pairs(moles) do
        if (mole.isNeedHit and not mole:CheckHitCount()) then
            return false
        end
    end
    return true
end

--===================
--检查是否回合结束(消失都处理完的时点)
--===================
function XUiHitMousePanelMoles.CheckRoundEnd(moles)
    for _, mole in pairs(moles) do
        if (not mole.RoundFinish) then
            return false
        end
    end
    return true
end

return XUiHitMousePanelMoles