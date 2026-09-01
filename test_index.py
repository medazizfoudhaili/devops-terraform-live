"""
Unit tests for Lambda handler
"""
import json
import pytest
from index import handler


class TestLambdaHandler:
    """Test suite for Lambda handler"""

    def test_handler_returns_200_status(self):
        """Test that handler returns 200 status code"""
        response = handler({}, {})
        assert response['statusCode'] == 200

    def test_handler_returns_json_body(self):
        """Test that handler returns valid JSON body"""
        response = handler({}, {})
        body = json.loads(response['body'])
        assert isinstance(body, dict)

    def test_handler_response_has_message(self):
        """Test that response contains message field"""
        response = handler({}, {})
        body = json.loads(response['body'])
        assert 'message' in body
        assert body['message'] == 'Hello from Terraform + LocalStack!'

    def test_handler_response_has_database_status(self):
        """Test that response contains database status"""
        response = handler({}, {})
        body = json.loads(response['body'])
        assert 'database_status' in body
        assert 'User created successfully' in body['database_status']

    def test_handler_response_has_table_name(self):
        """Test that response contains table name"""
        response = handler({}, {})
        body = json.loads(response['body'])
        assert 'table_name' in body

    def test_handler_response_structure(self):
        """Test complete response structure"""
        response = handler({}, {})
        assert 'statusCode' in response
        assert 'body' in response
        assert response['statusCode'] == 200
        
        body = json.loads(response['body'])
        assert len(body) >= 3
        assert all(key in body for key in ['message', 'database_status', 'table_name'])


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
