module Domain.User exposing (User, init)


type alias User =
    { id : String
    }


init : String -> User
init id =
    User id
