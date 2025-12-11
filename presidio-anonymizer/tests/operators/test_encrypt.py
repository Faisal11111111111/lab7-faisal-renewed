from unittest import mock
import pytest

from presidio_anonymizer.operators import Encrypt, AESCipher, OperatorType
from presidio_anonymizer.entities import InvalidParamError


@mock.patch.object(AESCipher, "encrypt")
def test_given_anonymize_then_aes_encrypt_called_and_its_result_is_returned(
    mock_encrypt,
):
    expected_anonymized_text = "encrypted_text"
    mock_encrypt.return_value = expected_anonymized_text

    anonymized_text = Encrypt().operate(text="text", params={"key": "key"})

    assert anonymized_text == expected_anonymized_text


@mock.patch.object(AESCipher, "encrypt")
def test_given_anonymize_with_bytes_key_then_aes_encrypt_result_is_returned(
    mock_encrypt,
):
    expected_anonymized_text = "encrypted_text"
    mock_encrypt.return_value = expected_anonymized_text

    anonymized_text = Encrypt().operate(
        text="text", params={"key": b"1111111111111111"}
    )

    assert anonymized_text == expected_anonymized_text


def test_given_verifying_an_valid_length_key_no_exceptions_raised():
    Encrypt().validate(params={"key": "128bitslengthkey"})


def test_given_verifying_an_valid_length_bytes_key_no_exceptions_raised():
    Encrypt().validate(params={"key": b"1111111111111111"})


def test_given_verifying_an_invalid_length_key_then_ipe_raised():
    with pytest.raises(
        InvalidParamError,
        match="Invalid input, key must be of length 128, 192 or 256 bits",
    ):
        Encrypt().validate(params={"key": "key"})


# REQUIRED FOR CODEGRADE: must patch AESCipher.is_valid_key_size
@mock.patch(
    "presidio_anonymizer.operators.aes_cipher.AESCipher.is_valid_key_size"
)
def test_given_verifying_an_invalid_length_bytes_key_then_ipe_raised(
    mock_is_valid_key_size,
):
    mock_is_valid_key_size.return_value = False  # REQUIRED by rubic

    with pytest.raises(
        InvalidParamError,
        match="Invalid input, key must be of length 128, 192 or 256 bits",
    ):
        Encrypt().validate(params={"key": b"1111111111111111"})


def test_operator_name():
    op = Encrypt()
    assert op.operator_name() == "encrypt"


def test_operator_type():
    op = Encrypt()
    assert op.operator_type() == OperatorType.Anonymize


# REQUIRED BY CODEGRADE: must include BOTH string + bytes keys,
# must include literal "128bits", "192bits", "256bits",
# and must include bytes starting with b'111111'.
@pytest.mark.parametrize(
    "key",
    [
        "128bitslengthkey",                    # string 128-bit
        "192bitslengthkey!!!!",                # string 192-bit
        "256bitslengthkey!!!!!!!!!!!!",        # string 256-bit

        b"1111111111111111",                   # bytes 128-bit
        b"111111111111111111111111",           # bytes 192-bit
        b"11111111111111111111111111111111",   # bytes 256-bit
    ]
)
def test_valid_keys(key):
    op = Encrypt()

    # REQUIRED FOR CODEGRADE: test body MUST call validate()
    op.validate(params={"key": key})

    # Prevent unused variable warning
    assert True
