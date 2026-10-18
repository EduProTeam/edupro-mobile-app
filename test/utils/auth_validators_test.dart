import 'package:edupro_mobile_app/features/auth/validation/auth_validators.dart';
import 'package:edupro_mobile_app/features/profile/validation/profile_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Authentication email validation', () {
    final cases = <(String, String, String?, String?)>[
      ('AUTH101', 'accepts an ordinary email', 'learner@example.com', null),
      (
        'AUTH102',
        'accepts surrounding whitespace',
        '  learner@example.com  ',
        null,
      ),
      (
        'AUTH103',
        'accepts a subdomain and plus address',
        'a+b@learn.example.edu',
        null,
      ),
      ('AUTH104', 'rejects null', null, 'Enter your email address.'),
      ('AUTH105', 'rejects an empty value', '', 'Enter your email address.'),
      (
        'AUTH106',
        'rejects whitespace only',
        ' \t ',
        'Enter your email address.',
      ),
      (
        'AUTH107',
        'rejects a missing at sign',
        'learner.example.com',
        'Enter a valid email address.',
      ),
      (
        'AUTH108',
        'rejects a missing domain suffix',
        'learner@example',
        'Enter a valid email address.',
      ),
      (
        'AUTH109',
        'rejects an empty local part',
        '@example.com',
        'Enter a valid email address.',
      ),
      (
        'AUTH110',
        'rejects embedded whitespace',
        'learn er@example.com',
        'Enter a valid email address.',
      ),
      (
        'AUTH111',
        'rejects multiple at signs',
        'a@@example.com',
        'Enter a valid email address.',
      ),
    ];

    for (final (id, scenario, input, expected) in cases) {
      test('$id email $scenario', () {
        // Arrange: each row supplies an independent input and expected result.
        final value = input;

        // Act.
        final result = AuthValidators.email(value);

        // Assert.
        expect(result, expected);
      });
    }
  });

  group('Login password validation', () {
    final cases = <(String, String, String?, String?)>[
      ('AUTH112', 'rejects null', null, 'Enter your password.'),
      ('AUTH113', 'rejects an empty password', '', 'Enter your password.'),
      ('AUTH114', 'allows a short existing password', 'x', null),
      ('AUTH115', 'preserves whitespace as password characters', ' ', null),
    ];
    for (final (id, scenario, input, expected) in cases) {
      test('$id login password $scenario', () {
        // Arrange.
        final value = input;
        // Act.
        final result = AuthValidators.loginPassword(value);
        // Assert.
        expect(result, expected);
      });
    }
  });

  group('Registration input validation', () {
    final nameCases = <(String, String, String?, String?)>[
      ('AUTH116', 'rejects null', null, 'Enter your full name.'),
      ('AUTH117', 'rejects whitespace only', '  ', 'Enter your full name.'),
      (
        'AUTH118',
        'accepts a single character under the existing rule',
        'A',
        null,
      ),
      ('AUTH119', 'accepts a trimmed full name', '  Alex Learner  ', null),
    ];
    for (final (id, scenario, input, expected) in nameCases) {
      test('$id registration full name $scenario', () {
        // Arrange.
        final value = input;
        // Act.
        final result = AuthValidators.registrationFullName(value);
        // Assert.
        expect(result, expected);
      });
    }

    final passwordCases = <(String, String, String?, String?)>[
      ('AUTH120', 'rejects null', null, 'Enter a password.'),
      ('AUTH121', 'rejects an empty password', '', 'Enter a password.'),
      (
        'AUTH122',
        'rejects five characters',
        'abcde',
        'Password must be at least 6 characters.',
      ),
      ('AUTH123', 'accepts the six character boundary', 'abcdef', null),
      ('AUTH124', 'accepts more than six characters', 'example-password', null),
      ('AUTH125', 'counts whitespace under the existing rule', '      ', null),
    ];
    for (final (id, scenario, input, expected) in passwordCases) {
      test('$id registration password $scenario', () {
        // Arrange.
        final value = input;
        // Act.
        final result = AuthValidators.registrationPassword(value);
        // Assert.
        expect(result, expected);
      });
    }

    final confirmationCases = <(String, String, String?, String?)>[
      ('AUTH126', 'rejects null', null, 'Confirm your password.'),
      (
        'AUTH127',
        'rejects an empty confirmation',
        '',
        'Confirm your password.',
      ),
      ('AUTH128', 'accepts an exact match', 'sample-password', null),
      (
        'AUTH129',
        'rejects different case',
        'Sample-password',
        'Passwords do not match.',
      ),
      (
        'AUTH130',
        'rejects surrounding whitespace',
        'sample-password ',
        'Passwords do not match.',
      ),
    ];
    for (final (id, scenario, input, expected) in confirmationCases) {
      test('$id password confirmation $scenario', () {
        // Arrange.
        const password = 'sample-password';
        // Act.
        final result = AuthValidators.confirmPassword(
          input,
          password: password,
        );
        // Assert.
        expect(result, expected);
      });
    }
  });

  group('Profile input validation', () {
    final cases = <(String, String, String?, String?)>[
      ('PROFILE001', 'rejects null', null, 'Enter your full name.'),
      ('PROFILE002', 'rejects whitespace only', '  ', 'Enter your full name.'),
      (
        'PROFILE003',
        'rejects a single trimmed character',
        ' A ',
        'Enter your full name.',
      ),
      ('PROFILE004', 'accepts the two character boundary', ' Al ', null),
      ('PROFILE005', 'accepts a full name', 'Alex Learner', null),
    ];
    for (final (id, scenario, input, expected) in cases) {
      test('$id profile name $scenario', () {
        // Arrange.
        final value = input;
        // Act.
        final result = ProfileValidators.fullName(value);
        // Assert.
        expect(result, expected);
      });
    }
  });
}
