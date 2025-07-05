let code = Struct("BlackjackCard") {
    Enum("Suit") {
        Case("spades").equals("♠")
        Case("hearts").equals("♡")
        Case("diamonds").equals("♢")
        Case("clubs").equals("♣")
    }
    .inherits("Character")
    .comment { Line("nested Suit enumeration") }
    
    Enum("Rank") {
        Case("ace").equals(1)
        Case("two").equals(2)
        Case("three").equals(3)
        Case("four").equals(4)
        Case("five").equals(5)
        Case("six").equals(6)
        Case("seven").equals(7)
        Case("eight").equals(8)
        Case("nine").equals(9)
        Case("ten").equals(10)
        Case("jack").equals(11)
        Case("queen").equals(12)
        Case("king").equals(13)
    }
    .inherits("Int")
    .comment { Line("nested Rank enumeration") }
}