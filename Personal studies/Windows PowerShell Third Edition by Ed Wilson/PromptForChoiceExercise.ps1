$caption = "this is the caption"
$message = "this is the message"
$choices = [System.Management.Automation.Host.ChoiceDescription[]] `
@("choice1", "choice2", "choice3")
[int]$defaultChoice = 2
$choiceRTN = $host.ui.PromptForChoice($caption, $message, $choices, $defaultChoice)

Switch ($choiceRTN) {
    0 { "choice1" }
    1 { "choice2" }
    2 { "choice3" }
}
